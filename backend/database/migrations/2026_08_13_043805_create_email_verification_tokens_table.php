<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * No email-verification token table is specified anywhere in the frozen
 * Database Design (section 3.1 documents password_reset_tokens but not an
 * equivalent for FR-104) -- per this session's resolution (see
 * ENGINEERING_DECISION_LOG.md), this mirrors password_reset_tokens' shape
 * exactly: single-use, expiring, SHA-256-hashed token keyed by email.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('email_verification_tokens', function (Blueprint $table) {
            $table->string('email', 190)->primary();
            $table->char('token_hash', 64);
            $table->timestamp('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('email_verification_tokens');
    }
};
