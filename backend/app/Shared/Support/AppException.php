<?php

namespace App\Shared\Support;

use Exception;

/**
 * Base for domain-specific exceptions that map to the standard error envelope
 * (docs/05-api-specification.md section 4) via a single handler mapping in
 * bootstrap/app.php -- see docs/coding-standards.md Exception Handling.
 */
abstract class AppException extends Exception
{
    public function __construct(
        protected string $errorCode,
        string $message,
        protected int $status,
        protected ?array $details = null,
    ) {
        parent::__construct($message);
    }

    public function errorCode(): string
    {
        return $this->errorCode;
    }

    public function status(): int
    {
        return $this->status;
    }

    public function details(): ?array
    {
        return $this->details;
    }
}
