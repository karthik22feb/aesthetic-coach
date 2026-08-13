<?php

namespace App\Modules\Auth\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Carries the plaintext verification token -- see PasswordResetMail's
 * docblock for why (identical reasoning, mirrored per this session's
 * resolution in ENGINEERING_DECISION_LOG.md).
 */
class EmailVerificationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public readonly string $token) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Verify your Aesthetic Coach email address',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.auth.email-verification',
            with: ['token' => $this->token],
        );
    }
}
