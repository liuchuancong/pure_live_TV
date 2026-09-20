package com.codenameakshay.async_wallpaper

/**
 * Bounded, deterministic validation for the small GLSL ES 1.00 contract used by the live
 * wallpaper renderer.
 *
 * This intentionally is not a GLSL compiler. It catches request-shape problems and constructs
 * that the ES2 renderer cannot safely provide, while the driver remains the authority for shader
 * compilation and linking on a real device.
 */
object ShaderProgramValidator {
  const val MAX_FRAGMENT_SHADER_BYTES = 64 * 1024
  const val MAX_TEXTURE_COUNT = 4
  const val MAX_TEXTURE_SOURCE_BYTES = 8L * 1024L * 1024L
  const val MAX_TEXTURE_DIMENSION = 4096
  const val MAX_TEXTURE_PIXELS = 4L * 1024L * 1024L
  const val MIN_FRAME_RATE = 1L
  const val MAX_FRAME_RATE = 60L
  const val MAX_UNIFORM_DECLARATIONS = 32
  const val MAX_UNIFORM_ARRAY_LENGTH = 16
  const val MAX_UNIFORM_COMPONENTS = 64L
  const val MAX_STATIC_LOOP_ITERATIONS = 128L

  /** Stable transport-facing error identifiers. Do not change [wireCode] once released. */
  enum class ErrorCode(val wireCode: String) {
    OPENGL_ES2_UNAVAILABLE("opengl-es2-unavailable"),
    SHADER_MAIN_MISSING("shader-main-missing"),
    SHADER_SOURCE_TOO_LARGE("shader-source-too-large"),
    SHADER_INVALID_COMMENT("shader-invalid-comment"),
    SHADER_VERSION_UNSUPPORTED("shader-version-unsupported"),
    SHADER_DIRECTIVE_UNSUPPORTED("shader-directive-unsupported"),
    SHADER_FORBIDDEN_CONSTRUCT("shader-forbidden-construct"),
    SHADER_DYNAMIC_LOOP("shader-dynamic-loop"),
    SHADER_LOOP_LIMIT_EXCEEDED("shader-loop-limit-exceeded"),
    SHADER_UNIFORM_INVALID("shader-uniform-invalid"),
    SHADER_UNIFORM_TYPE_UNSUPPORTED("shader-uniform-type-unsupported"),
    SHADER_UNIFORM_TYPE_MISMATCH("shader-uniform-type-mismatch"),
    SHADER_UNIFORM_LIMIT_EXCEEDED("shader-uniform-limit-exceeded"),
    SHADER_UNIFORM_ARRAY_TOO_LARGE("shader-uniform-array-too-large"),
    SHADER_SAMPLER_UNSUPPORTED("shader-sampler-unsupported"),
    TEXTURE_COUNT_EXCEEDED("texture-count-exceeded"),
    TEXTURE_SOURCE_TOO_LARGE("texture-source-too-large"),
    TEXTURE_SIZE_INVALID("texture-size-invalid"),
    TEXTURE_DIMENSIONS_EXCEEDED("texture-dimensions-exceeded"),
    TEXTURE_SOURCE_UNAVAILABLE("texture-source-unavailable"),
    FRAME_RATE_OUT_OF_RANGE("frame-rate-out-of-range"),
    CONFIGURATION_STORE_FAILED("opengl-configuration-store-failed"),
  }

  /**
   * Size metadata available before an image is decoded. Unknown source sizes are allowed here;
   * [GlRenderer] enforces the same limits while opening the source on its render thread.
   */
  data class TextureInput(
    val sourceSizeBytes: Long? = null,
    val width: Int? = null,
    val height: Int? = null,
  )

  data class Request(
    val fragmentShader: String?,
    val textures: List<TextureInput> = emptyList(),
    val frameRate: Long?,
    val openGlEs2Available: Boolean = true,
  )

  data class ValidationError(
    val code: ErrorCode,
    val message: String,
  ) {
    val wireCode: String
      get() = code.wireCode
  }

  sealed class Result {
    data object Valid : Result()

    data class Invalid(val error: ValidationError) : Result()

    val isValid: Boolean
      get() = this is Valid
  }

  fun validate(
    fragmentShader: String?,
    textures: List<TextureInput> = emptyList(),
    frameRate: Long?,
    openGlEs2Available: Boolean = true,
  ): Result {
    return validate(
      Request(
        fragmentShader = fragmentShader,
        textures = textures,
        frameRate = frameRate,
        openGlEs2Available = openGlEs2Available,
      ),
    )
  }

  fun validate(request: Request): Result {
    if (!request.openGlEs2Available) {
      return invalid(
        ErrorCode.OPENGL_ES2_UNAVAILABLE,
        "This device does not advertise OpenGL ES 2.0 support.",
      )
    }

    val frameRate = request.frameRate
    if (frameRate == null || frameRate !in MIN_FRAME_RATE..MAX_FRAME_RATE) {
      return invalid(
        ErrorCode.FRAME_RATE_OUT_OF_RANGE,
        "Frame rate must be between $MIN_FRAME_RATE and $MAX_FRAME_RATE FPS.",
      )
    }

    val textureError = validateTextures(request.textures)
    if (textureError != null) {
      return Result.Invalid(textureError)
    }

    val shader = request.fragmentShader
    if (shader == null) {
      return invalid(ErrorCode.SHADER_MAIN_MISSING, "A fragment shader with void main() is required.")
    }
    if (shader.toByteArray(Charsets.UTF_8).size > MAX_FRAGMENT_SHADER_BYTES) {
      return invalid(
        ErrorCode.SHADER_SOURCE_TOO_LARGE,
        "Fragment shader source exceeds $MAX_FRAGMENT_SHADER_BYTES UTF-8 bytes.",
      )
    }

    val uncommented = stripComments(shader)
      ?: return invalid(ErrorCode.SHADER_INVALID_COMMENT, "Fragment shader contains an unterminated block comment.")
    if (!MAIN_ENTRY_POINT.containsMatchIn(uncommented)) {
      return invalid(ErrorCode.SHADER_MAIN_MISSING, "Fragment shader must declare void main().")
    }

    validateDirectives(uncommented)?.let { return Result.Invalid(it) }
    validateForbiddenConstructs(uncommented)?.let { return Result.Invalid(it) }
    validateLoops(uncommented)?.let { return Result.Invalid(it) }
    validateUniforms(uncommented, request.textures.size)?.let { return Result.Invalid(it) }

    return Result.Valid
  }

  private fun validateTextures(textures: List<TextureInput>): ValidationError? {
    if (textures.size > MAX_TEXTURE_COUNT) {
      return error(
        ErrorCode.TEXTURE_COUNT_EXCEEDED,
        "At most $MAX_TEXTURE_COUNT textures may be supplied.",
      )
    }

    textures.forEachIndexed { index, texture ->
      val sourceSize = texture.sourceSizeBytes
      if (sourceSize != null) {
        if (sourceSize <= 0L) {
          return error(
            ErrorCode.TEXTURE_SIZE_INVALID,
            "Texture $index must have a positive encoded source size.",
          )
        }
        if (sourceSize > MAX_TEXTURE_SOURCE_BYTES) {
          return error(
            ErrorCode.TEXTURE_SOURCE_TOO_LARGE,
            "Texture $index exceeds the $MAX_TEXTURE_SOURCE_BYTES-byte source limit.",
          )
        }
      }

      val width = texture.width
      val height = texture.height
      if ((width == null) != (height == null)) {
        return error(
          ErrorCode.TEXTURE_SIZE_INVALID,
          "Texture $index must provide both dimensions or neither dimension.",
        )
      }
      if (width != null && height != null) {
        if (width <= 0 || height <= 0) {
          return error(
            ErrorCode.TEXTURE_SIZE_INVALID,
            "Texture $index dimensions must be positive.",
          )
        }
        val pixels = width.toLong() * height.toLong()
        if (width > MAX_TEXTURE_DIMENSION ||
          height > MAX_TEXTURE_DIMENSION ||
          pixels > MAX_TEXTURE_PIXELS
        ) {
          return error(
            ErrorCode.TEXTURE_DIMENSIONS_EXCEEDED,
            "Texture $index exceeds the configured decoded-size limit.",
          )
        }
      }
    }
    return null
  }

  private fun validateDirectives(source: String): ValidationError? {
    DIRECTIVE.findAll(source).forEach { directive ->
      val name = directive.groupValues[1].lowercase()
      val arguments = directive.groupValues[2].trim()
      when (name) {
        "version" -> {
          if (arguments != "100") {
            return error(
              ErrorCode.SHADER_VERSION_UNSUPPORTED,
              "Only GLSL ES 1.00 (#version 100) is supported by this renderer.",
            )
          }
        }
        "define", "if", "ifdef", "ifndef", "elif", "else", "endif" -> Unit
        else -> {
          return error(
            ErrorCode.SHADER_DIRECTIVE_UNSUPPORTED,
            "The #$name directive is not available in the ES2 wallpaper shader contract.",
          )
        }
      }
    }
    return null
  }

  private fun validateForbiddenConstructs(source: String): ValidationError? {
    if (FORBIDDEN_CONSTRUCT.containsMatchIn(source)) {
      return error(
        ErrorCode.SHADER_FORBIDDEN_CONSTRUCT,
        "Shader uses a construct unavailable to the OpenGL ES 2.0 renderer.",
      )
    }
    if (UNBOUNDED_LOOP.containsMatchIn(source)) {
      return error(
        ErrorCode.SHADER_FORBIDDEN_CONSTRUCT,
        "while and do-while loops are not allowed in wallpaper shaders.",
      )
    }
    return null
  }

  private fun validateLoops(source: String): ValidationError? {
    FOR_LOOP_START.findAll(source).forEach { start ->
      val openingParenthesis = source.indexOf('(', start.range.first)
      val closingParenthesis = findMatchingParenthesis(source, openingParenthesis)
        ?: return error(
          ErrorCode.SHADER_DYNAMIC_LOOP,
          "A for loop has an incomplete header.",
        )
      val header = source.substring(openingParenthesis + 1, closingParenthesis).trim()
      val parsed = STATIC_FOR_LOOP.matchEntire(header)
        ?: return error(
          ErrorCode.SHADER_DYNAMIC_LOOP,
          "Only simple integer for loops with static bounds are supported.",
        )

      val initial = parsed.groupValues[2].toLongOrNull()
        ?: return error(ErrorCode.SHADER_DYNAMIC_LOOP, "For-loop initial value is not an integer.")
      val comparison = parsed.groupValues[3]
      val bound = parsed.groupValues[4].toLongOrNull()
        ?: return error(ErrorCode.SHADER_DYNAMIC_LOOP, "For-loop bound is not an integer.")
      val update = parsed.groupValues[5]
      val step = loopStep(update)
        ?: return error(ErrorCode.SHADER_DYNAMIC_LOOP, "For-loop update is not statically bounded.")
      val iterations = loopIterations(initial, comparison, bound, step)
        ?: return error(ErrorCode.SHADER_DYNAMIC_LOOP, "For-loop does not make progress toward its bound.")
      if (iterations > MAX_STATIC_LOOP_ITERATIONS) {
        return error(
          ErrorCode.SHADER_LOOP_LIMIT_EXCEEDED,
          "For loops may execute at most $MAX_STATIC_LOOP_ITERATIONS iterations.",
        )
      }
    }
    return null
  }

  private fun validateUniforms(source: String, suppliedTextureCount: Int): ValidationError? {
    var declarations = 0
    var components = 0L
    val suppliedTextureIndexes = HashSet<Int>()

    UNIFORM_STATEMENT.findAll(source).forEach { statement ->
      val declaration = UNIFORM_DECLARATION.matchEntire(statement.groupValues[1].trim())
        ?: return error(
          ErrorCode.SHADER_UNIFORM_INVALID,
          "Uniform declarations must contain one simple ES2 uniform per statement.",
        )
      declarations += 1
      if (declarations > MAX_UNIFORM_DECLARATIONS) {
        return error(
          ErrorCode.SHADER_UNIFORM_LIMIT_EXCEEDED,
          "At most $MAX_UNIFORM_DECLARATIONS uniform declarations are allowed.",
        )
      }

      val type = declaration.groupValues[1]
      val name = declaration.groupValues[2]
      val arrayLength = declaration.groupValues[3].ifEmpty { "1" }.toIntOrNull()
        ?: return error(ErrorCode.SHADER_UNIFORM_INVALID, "Uniform array length must be an integer.")
      if (arrayLength !in 1..MAX_UNIFORM_ARRAY_LENGTH) {
        return error(
          ErrorCode.SHADER_UNIFORM_ARRAY_TOO_LARGE,
          "Uniform arrays may contain at most $MAX_UNIFORM_ARRAY_LENGTH elements.",
        )
      }

      val componentCost = UNIFORM_COMPONENT_COST[type]
        ?: return error(
          ErrorCode.SHADER_UNIFORM_TYPE_UNSUPPORTED,
          "Uniform type $type is not supported by the ES2 wallpaper shader contract.",
        )
      components += componentCost * arrayLength.toLong()
      if (components > MAX_UNIFORM_COMPONENTS) {
        return error(
          ErrorCode.SHADER_UNIFORM_LIMIT_EXCEEDED,
          "Uniforms exceed the $MAX_UNIFORM_COMPONENTS-component request limit.",
        )
      }

      val expectedType = RENDERER_UNIFORM_TYPES[name]
      if (expectedType != null && (type != expectedType || arrayLength != 1)) {
        return error(
          ErrorCode.SHADER_UNIFORM_TYPE_MISMATCH,
          "Renderer uniform $name must be declared as $expectedType.",
        )
      }

      if (TEXTURE_UNIFORM_NAME.matches(name) && (type != "sampler2D" || arrayLength != 1)) {
        return error(
          ErrorCode.SHADER_UNIFORM_TYPE_MISMATCH,
          "Texture uniform $name must be a non-array sampler2D.",
        )
      }

      if (type.startsWith("sampler")) {
        val textureMatch = TEXTURE_UNIFORM_NAME.matchEntire(name)
          ?: return error(
            ErrorCode.SHADER_SAMPLER_UNSUPPORTED,
            "Only sampler2D uniforms named u_texture0 through u_texture3 are supported.",
          )
        if (type != "sampler2D" || arrayLength != 1) {
          return error(
            ErrorCode.SHADER_UNIFORM_TYPE_MISMATCH,
            "Texture uniform $name must be a non-array sampler2D.",
          )
        }
        val index = textureMatch.groupValues[1].toInt()
        if (index >= suppliedTextureCount) {
          return error(
            ErrorCode.TEXTURE_SOURCE_UNAVAILABLE,
            "Shader declares $name but no texture was supplied for that slot.",
          )
        }
        suppliedTextureIndexes += index
      }
    }

    if (suppliedTextureIndexes.size > MAX_TEXTURE_COUNT) {
      return error(
        ErrorCode.TEXTURE_COUNT_EXCEEDED,
        "Shader declares more texture uniforms than the renderer supports.",
      )
    }
    return null
  }

  private fun loopStep(update: String): Long? {
    return when {
      "++" in update -> 1L
      "--" in update -> -1L
      "+=" in update -> update.substringAfter("+=").trim().toLongOrNull()?.takeIf { it > 0L }
      "-=" in update -> update.substringAfter("-=").trim().toLongOrNull()?.takeIf { it > 0L }?.unaryMinus()
      else -> null
    }
  }

  private fun loopIterations(initial: Long, comparison: String, bound: Long, step: Long): Long? {
    return when (comparison) {
      "<" -> {
        if (step <= 0L) null else if (initial >= bound) 0L else ceilDiv(bound - initial, step)
      }
      "<=" -> {
        if (step <= 0L) null else if (initial > bound) 0L else ((bound - initial) / step) + 1L
      }
      ">" -> {
        if (step >= 0L) null else if (initial <= bound) 0L else ceilDiv(initial - bound, -step)
      }
      ">=" -> {
        if (step >= 0L) null else if (initial < bound) 0L else ((initial - bound) / -step) + 1L
      }
      else -> null
    }
  }

  private fun ceilDiv(numerator: Long, denominator: Long): Long {
    return ((numerator - 1L) / denominator) + 1L
  }

  private fun findMatchingParenthesis(source: String, openingParenthesis: Int): Int? {
    if (openingParenthesis < 0) {
      return null
    }
    var depth = 0
    for (index in openingParenthesis until source.length) {
      when (source[index]) {
        '(' -> depth += 1
        ')' -> {
          depth -= 1
          if (depth == 0) {
            return index
          }
        }
      }
    }
    return null
  }

  private fun stripComments(source: String): String? {
    val result = StringBuilder(source.length)
    var index = 0
    while (index < source.length) {
      if (source[index] == '/' && index + 1 < source.length) {
        when (source[index + 1]) {
          '/' -> {
            result.append(' ').append(' ')
            index += 2
            while (index < source.length && source[index] != '\n') {
              result.append(' ')
              index += 1
            }
            continue
          }
          '*' -> {
            result.append(' ').append(' ')
            index += 2
            var closed = false
            while (index < source.length) {
              if (source[index] == '*' && index + 1 < source.length && source[index + 1] == '/') {
                result.append(' ').append(' ')
                index += 2
                closed = true
                break
              }
              result.append(if (source[index] == '\n') '\n' else ' ')
              index += 1
            }
            if (!closed) {
              return null
            }
            continue
          }
        }
      }
      result.append(source[index])
      index += 1
    }
    return result.toString()
  }

  private fun invalid(code: ErrorCode, message: String): Result.Invalid = Result.Invalid(error(code, message))

  private fun error(code: ErrorCode, message: String): ValidationError = ValidationError(code, message)

  private val MAIN_ENTRY_POINT = Regex("""\bvoid\s+main\s*\(\s*\)""")
  private val DIRECTIVE = Regex("""(?m)^[\t ]*#\s*([A-Za-z_][A-Za-z0-9_]*)\b(.*)$""")
  private val FORBIDDEN_CONSTRUCT = Regex(
    """\b(?:samplerExternalOES|sampler2DArray|sampler3D|samplerCube|image[A-Za-z0-9_]*|atomic[A-Za-z0-9_]*|layout|buffer|shared|coherent|readonly|writeonly|gl_FragData|gl_FragDepth|gl_InstanceID|gl_VertexID|texelFetch|textureLod|textureGrad|textureOffset|dFdx|dFdy|fwidth)\b""",
  )
  private val UNBOUNDED_LOOP = Regex("""\b(?:while|do)\b""")
  private val FOR_LOOP_START = Regex("""\bfor\s*\(""")
  private val STATIC_FOR_LOOP = Regex(
    """(?:int|float)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(-?\d+)\s*;\s*\1\s*(<=|<|>=|>)\s*(-?\d+)\s*;\s*((?:\1\s*(?:\+\+|--|\+=\s*\d+|-=\s*\d+))|(?:(?:\+\+|--)\s*\1))""",
  )
  private val UNIFORM_STATEMENT = Regex("""\buniform\b([^;]*);""")
  private val UNIFORM_DECLARATION = Regex(
    """(?:(?:lowp|mediump|highp)\s+)?([A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*\[\s*(\d+)\s*])?""",
  )
  private val TEXTURE_UNIFORM_NAME = Regex("""u_texture([0-3])""")

  private val UNIFORM_COMPONENT_COST = mapOf(
    "bool" to 1L,
    "int" to 1L,
    "float" to 1L,
    "vec2" to 2L,
    "vec3" to 3L,
    "vec4" to 4L,
    "bvec2" to 2L,
    "bvec3" to 3L,
    "bvec4" to 4L,
    "ivec2" to 2L,
    "ivec3" to 3L,
    "ivec4" to 4L,
    "mat2" to 4L,
    "mat3" to 9L,
    "mat4" to 16L,
    "sampler2D" to 1L,
  )

  private val RENDERER_UNIFORM_TYPES = mapOf(
    "u_time" to "float",
    "u_resolution" to "vec2",
    "u_touch" to "vec2",
    "u_offset" to "vec2",
  )
}
