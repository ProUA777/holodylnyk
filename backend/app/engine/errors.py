class EngineError(Exception):
    """Помилка, яку можна безпечно показати клієнту."""

    status_code = 400
    code = "engine_error"

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class BadImageError(EngineError):
    code = "bad_image"


class ImageTooLargeError(EngineError):
    status_code = 413
    code = "image_too_large"


class ProfileNotFoundError(EngineError):
    status_code = 404
    code = "profile_not_found"


class AIUnavailableError(EngineError):
    status_code = 503
    code = "ai_unavailable"


class AIBadResponseError(EngineError):
    status_code = 502
    code = "ai_bad_response"


class NotAFoodPhotoError(EngineError):
    """Профіль може кинути, якщо на фото нічого придатного (немає їжі, цеглинок...)."""

    status_code = 422
    code = "nothing_recognized"
