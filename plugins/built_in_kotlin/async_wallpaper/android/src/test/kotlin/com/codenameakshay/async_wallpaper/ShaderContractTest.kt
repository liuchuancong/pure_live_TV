package com.codenameakshay.async_wallpaper

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.nio.file.Files

/**
 * JVM-only contract coverage. GLES shader compilation/linking depends on an actual driver and is
 * deliberately verified on a device or emulator instead of being faked in these unit tests.
 */
class ShaderContractTest {
  @Test
  fun acceptsABoundedEs2ShaderContract() {
    val result = ShaderProgramValidator.validate(
      fragmentShader = """
        precision mediump float;
        varying vec2 v_uv;
        uniform float u_time;
        uniform vec2 u_resolution;
        uniform sampler2D u_texture0;

        void main() {
          gl_FragColor = texture2D(u_texture0, v_uv) * (0.5 + 0.5 * sin(u_time));
        }
      """.trimIndent(),
      textures = listOf(ShaderProgramValidator.TextureInput(sourceSizeBytes = 1024L)),
      frameRate = 30L,
    )

    assertTrue(result is ShaderProgramValidator.Result.Valid)
  }

  @Test
  fun requiresARealMainEntryPointWithStableErrorCode() {
    assertEquals(
      ShaderProgramValidator.ErrorCode.SHADER_MAIN_MISSING.wireCode,
      invalidCode(
        ShaderProgramValidator.Request(
          fragmentShader = "// void main() {}\nprecision mediump float;",
          frameRate = 30L,
        ),
      ),
    )
  }

  @Test
  fun boundsFragmentSourceByUtf8ByteCount() {
    val source = "void main() {}\n" + "x".repeat(ShaderProgramValidator.MAX_FRAGMENT_SHADER_BYTES)

    assertEquals(
      ShaderProgramValidator.ErrorCode.SHADER_SOURCE_TOO_LARGE.wireCode,
      invalidCode(ShaderProgramValidator.Request(fragmentShader = source, frameRate = 30L)),
    )
  }

  @Test
  fun boundsTextureCountAndEncodedTextureSize() {
    val tooManyTextures = List(ShaderProgramValidator.MAX_TEXTURE_COUNT + 1) {
      ShaderProgramValidator.TextureInput(sourceSizeBytes = 1L)
    }
    assertEquals(
      ShaderProgramValidator.ErrorCode.TEXTURE_COUNT_EXCEEDED.wireCode,
      invalidCode(
        ShaderProgramValidator.Request(
          fragmentShader = basicShader(),
          textures = tooManyTextures,
          frameRate = 30L,
        ),
      ),
    )

    assertEquals(
      ShaderProgramValidator.ErrorCode.TEXTURE_SOURCE_TOO_LARGE.wireCode,
      invalidCode(
        ShaderProgramValidator.Request(
          fragmentShader = basicShader(),
          textures = listOf(
            ShaderProgramValidator.TextureInput(
              sourceSizeBytes = ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES + 1L,
            ),
          ),
          frameRate = 30L,
        ),
      ),
    )
  }

  @Test
  fun boundsUniformArraysBeforeDriverCompilation() {
    val source = """
      precision mediump float;
      uniform float payload[${ShaderProgramValidator.MAX_UNIFORM_ARRAY_LENGTH + 1}];
      void main() { gl_FragColor = vec4(1.0); }
    """.trimIndent()

    assertEquals(
      ShaderProgramValidator.ErrorCode.SHADER_UNIFORM_ARRAY_TOO_LARGE.wireCode,
      invalidCode(ShaderProgramValidator.Request(fragmentShader = source, frameRate = 30L)),
    )
  }

  @Test
  fun boundsFrameRateAtBothEnds() {
    assertEquals(
      ShaderProgramValidator.ErrorCode.FRAME_RATE_OUT_OF_RANGE.wireCode,
      invalidCode(ShaderProgramValidator.Request(fragmentShader = basicShader(), frameRate = 0L)),
    )
    assertEquals(
      ShaderProgramValidator.ErrorCode.FRAME_RATE_OUT_OF_RANGE.wireCode,
      invalidCode(
        ShaderProgramValidator.Request(
          fragmentShader = basicShader(),
          frameRate = ShaderProgramValidator.MAX_FRAME_RATE + 1L,
        ),
      ),
    )
  }

  @Test
  fun reportsOpenGlCapabilityFailureWithoutTouchingAGpu() {
    assertEquals(
      ShaderProgramValidator.ErrorCode.OPENGL_ES2_UNAVAILABLE.wireCode,
      invalidCode(
        ShaderProgramValidator.Request(
          fragmentShader = basicShader(),
          frameRate = 30L,
          openGlEs2Available = false,
        ),
      ),
    )
  }

  @Test
  fun rejectsUnavailableAndPotentiallyUnboundedConstructs() {
    val externalSampler = """
      precision mediump float;
      uniform samplerExternalOES u_texture0;
      void main() { gl_FragColor = vec4(1.0); }
    """.trimIndent()
    assertEquals(
      ShaderProgramValidator.ErrorCode.SHADER_FORBIDDEN_CONSTRUCT.wireCode,
      invalidCode(
        ShaderProgramValidator.Request(
          fragmentShader = externalSampler,
          textures = listOf(ShaderProgramValidator.TextureInput(sourceSizeBytes = 1L)),
          frameRate = 30L,
        ),
      ),
    )

    val dynamicLoop = """
      precision mediump float;
      void main() {
        int i = 0;
        while (i < 4) { i++; }
        gl_FragColor = vec4(1.0);
      }
    """.trimIndent()
    assertEquals(
      ShaderProgramValidator.ErrorCode.SHADER_FORBIDDEN_CONSTRUCT.wireCode,
      invalidCode(ShaderProgramValidator.Request(fragmentShader = dynamicLoop, frameRate = 30L)),
    )
  }

  @Test
  fun deletesOnlyDirectOpenGlGenerationDirectories() {
    val root = Files.createTempDirectory("async-wallpaper-opengl-root").toFile()
    val outside = Files.createTempDirectory("async-wallpaper-opengl-outside").toFile()
    try {
      val obsolete = File(root, "configuration-obsolete").apply {
        assertTrue(mkdir())
      }
      File(obsolete, "texture.texture").writeText("texture")
      val current = File(root, "configuration-current").apply {
        assertTrue(mkdir())
      }
      val unrelated = File(root, "unrelated-data").apply {
        assertTrue(mkdir())
      }
      val foreignGeneration = File(outside, "configuration-foreign").apply {
        assertTrue(mkdir())
      }

      assertTrue(deleteOpenGlGenerationDirectory(root, obsolete))
      assertFalse(obsolete.exists())
      assertTrue(current.exists())
      assertTrue(unrelated.exists())
      assertFalse(deleteOpenGlGenerationDirectory(root, foreignGeneration))
      assertTrue(foreignGeneration.exists())
    } finally {
      root.deleteRecursively()
      outside.deleteRecursively()
    }
  }

  private fun invalidCode(request: ShaderProgramValidator.Request): String {
    val result = ShaderProgramValidator.validate(request)
    assertTrue("Expected invalid request, but was $result", result is ShaderProgramValidator.Result.Invalid)
    return (result as ShaderProgramValidator.Result.Invalid).error.wireCode
  }

  private fun basicShader(): String {
    return "precision mediump float; void main() { gl_FragColor = vec4(1.0); }"
  }
}
