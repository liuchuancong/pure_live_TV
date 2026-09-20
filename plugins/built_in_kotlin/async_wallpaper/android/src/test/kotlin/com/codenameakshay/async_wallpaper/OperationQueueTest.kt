package com.codenameakshay.async_wallpaper

import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OperationQueueTest {
  @Test
  fun `main thread gate cancels a pending action before it can begin`() {
    val gate = MainThreadOperationGate()

    assertTrue(gate.cancelBeforeStart())
    assertFalse(gate.begin())
    assertEquals(MainThreadOperationGate.State.CANCELLED, gate.currentState())
  }

  @Test
  fun `main thread gate cannot cancel an action that has already begun`() {
    val gate = MainThreadOperationGate()

    assertTrue(gate.begin())
    assertFalse(gate.cancelBeforeStart())
    gate.complete()
    assertEquals(MainThreadOperationGate.State.COMPLETED, gate.currentState())
  }

  @Test
  fun `operations and callbacks preserve submission order`() {
    val executor = Executors.newSingleThreadExecutor()
    val queue = OperationQueue(executor)
    val operations = Collections.synchronizedList(mutableListOf<Int>())
    val callbacks = Collections.synchronizedList(mutableListOf<Int>())
    val completed = CountDownLatch(3)

    try {
      repeat(3) { index ->
        queue.submit(
          operation = {
            operations += index
            index
          },
          callback = { result ->
            callbacks += result.getOrThrow()
            completed.countDown()
          },
        )
      }

      assertTrue(completed.await(5, TimeUnit.SECONDS))
      assertEquals(listOf(0, 1, 2), operations)
      assertEquals(listOf(0, 1, 2), callbacks)
    } finally {
      queue.shutdown()
      executor.awaitTermination(5, TimeUnit.SECONDS)
    }
  }

  @Test
  fun `thrown operation completes its callback exactly once`() {
    val executor = Executors.newSingleThreadExecutor()
    val queue = OperationQueue(executor)
    val callbackCount = AtomicInteger()
    val completed = CountDownLatch(1)

    try {
      queue.submit(
        operation = { error("simulated failure") },
        callback = { result ->
          callbackCount.incrementAndGet()
          assertTrue(result.isFailure)
          completed.countDown()
        },
      )

      assertTrue(completed.await(5, TimeUnit.SECONDS))
      queue.shutdown()
      assertTrue(executor.awaitTermination(5, TimeUnit.SECONDS))
      assertEquals(1, callbackCount.get())
    } finally {
      queue.shutdown()
    }
  }

  @Test
  fun `shutdown rejects later work while draining already accepted work`() {
    val executor = Executors.newSingleThreadExecutor()
    val queue = OperationQueue(executor)
    val firstStarted = CountDownLatch(1)
    val releaseFirst = CountDownLatch(1)
    val acceptedCompleted = CountDownLatch(2)
    val rejectedCompleted = CountDownLatch(1)
    val rejectedCallbackCount = AtomicInteger()
    val executed = Collections.synchronizedList(mutableListOf<String>())

    try {
      queue.submit(
        operation = {
          firstStarted.countDown()
          assertTrue(releaseFirst.await(5, TimeUnit.SECONDS))
          executed += "first"
          "first"
        },
        callback = {
          acceptedCompleted.countDown()
        },
      )
      assertTrue(firstStarted.await(5, TimeUnit.SECONDS))
      queue.submit(
        operation = {
          executed += "second"
          "second"
        },
        callback = {
          acceptedCompleted.countDown()
        },
      )

      queue.shutdown()
      queue.submit(
        operation = {
          executed += "rejected"
          "rejected"
        },
        callback = { result ->
          rejectedCallbackCount.incrementAndGet()
          assertTrue(result.exceptionOrNull() is OperationQueueShutdownException)
          rejectedCompleted.countDown()
        },
      )

      assertTrue(rejectedCompleted.await(5, TimeUnit.SECONDS))
      releaseFirst.countDown()
      assertTrue(acceptedCompleted.await(5, TimeUnit.SECONDS))
      assertTrue(executor.awaitTermination(5, TimeUnit.SECONDS))
      assertEquals(listOf("first", "second"), executed)
      assertFalse(executed.contains("rejected"))
      assertEquals(1, rejectedCallbackCount.get())
    } finally {
      releaseFirst.countDown()
      queue.shutdown()
    }
  }
}
