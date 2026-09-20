package com.codenameakshay.async_wallpaper

import java.util.concurrent.atomic.AtomicReference

/**
 * Coordinates a queued main-thread action with the worker waiting for it.
 *
 * A timeout may cancel only a still-pending action. Once the main thread has begun it, the caller
 * waits for completion so a late system-UI launch or mutation can never happen after its result
 * was reported to Flutter.
 */
internal class MainThreadOperationGate {
  private val state = AtomicReference(State.PENDING)

  fun begin(): Boolean = state.compareAndSet(State.PENDING, State.RUNNING)

  fun cancelBeforeStart(): Boolean = state.compareAndSet(State.PENDING, State.CANCELLED)

  fun complete() {
    state.compareAndSet(State.RUNNING, State.COMPLETED)
  }

  internal fun currentState(): State = state.get()

  internal enum class State {
    PENDING,
    RUNNING,
    CANCELLED,
    COMPLETED,
  }
}
