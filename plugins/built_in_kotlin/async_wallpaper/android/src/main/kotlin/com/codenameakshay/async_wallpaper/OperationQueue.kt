package com.codenameakshay.async_wallpaper

import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ThreadFactory
import java.util.concurrent.atomic.AtomicBoolean

/**
 * A small, single-worker queue for operations that must not overlap.
 *
 * Wallpaper writes, media preparation, and persisted renderer configuration all mutate a shared
 * system or app-private resource. Keeping them on one worker makes their ordering explicit and
 * avoids the races caused by a cached pool. Accepted work drains during [shutdown]; later
 * submissions receive [OperationQueueShutdownException] exactly once.
 */
class OperationQueue(
  private val executor: ExecutorService = Executors.newSingleThreadExecutor(QueueThreadFactory()),
) {
  private val lock = Any()
  private var acceptingWork = true

  /**
   * Submits [operation] in FIFO order. The callback is completed once even when the worker is
   * rejected while shutdown races with submission.
   */
  fun <T> submit(
    operation: () -> T,
    callback: (Result<T>) -> Unit,
  ) {
    val completion = OnceCompletion(callback)
    synchronized(lock) {
      if (!acceptingWork) {
        completion.complete(Result.failure(OperationQueueShutdownException()))
        return
      }

      try {
        executor.execute {
          completion.complete(runCatching(operation))
        }
      } catch (error: RejectedExecutionException) {
        // An externally supplied executor can reject despite acceptingWork still being true.
        // Treat that just like shutdown rather than losing the transport callback.
        acceptingWork = false
        completion.complete(Result.failure(OperationQueueShutdownException(error)))
      }
    }
  }

  /** Stops accepting new work while allowing already accepted operations to finish in order. */
  fun shutdown() {
    synchronized(lock) {
      acceptingWork = false
      executor.shutdown()
    }
  }

  private class OnceCompletion<T>(
    private val callback: (Result<T>) -> Unit,
  ) {
    private val completed = AtomicBoolean(false)

    fun complete(result: Result<T>) {
      if (completed.compareAndSet(false, true)) {
        callback(result)
      }
    }
  }

  private class QueueThreadFactory : ThreadFactory {
    override fun newThread(runnable: Runnable): Thread {
      return Thread(runnable, "AsyncWallpaper-Operations").apply {
        isDaemon = true
      }
    }
  }
}

/** Stable failure used when a plugin instance no longer owns an operation queue. */
class OperationQueueShutdownException(
  cause: Throwable? = null,
) : IllegalStateException("The wallpaper operation queue has been shut down.", cause)
