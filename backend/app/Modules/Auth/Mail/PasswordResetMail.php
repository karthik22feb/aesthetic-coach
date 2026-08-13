<?php

namespace App\Modules\Auth\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Carries the plaintext reset token -- necessarily, since this is the only
 * channel the token is ever transmitted through (never returned by any API
 * response, never logged). Queued (see AuthService::forgotPassword()) so
 * dispatching it doesn't add a found-vs-not-found timing signal to the
 * anti-enumeration response.
 */
class PasswordResetMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public readonly string $token) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Reset your Aesthetic Coach password',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.auth.password-reset',
            with: ['token' => $this->token],
        );
    }
}
