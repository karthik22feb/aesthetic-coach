<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Brings password_reset_tokens in line with the frozen schema (Database
 * Design section 3.1: `email` PK, `token_hash` CHAR(64), `expires_at`
 * TIMESTAMP) -- the table previously had Laravel's unmodified default shape
 * (`token` VARCHAR, `created_at`), flagged as a known inconsistency since
 * the Authentication Foundation session and never corrected because the
 * password-reset feature didn't exist yet. The table has never held real
 * data (feature unimplemented until now), so this is a destructive column
 * swap rather than a data migration.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->dropColumn(['token', 'created_at']);
        });

        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->char('token_hash', 64);
            $table->timestamp('expires_at');
        });

        // The original column inherited string('email')'s 255-char default;
        // the frozen spec (and users.email, email_verification_tokens.email)
        // is VARCHAR(190) -- corrected here for consistency. The column is
        // already the primary key (from the original migration), so this
        // only needs to change its length, not redeclare the key.
        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->string('email', 190)->change();
        });
    }

    public function down(): void
    {
        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->change();
        });

        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->dropColumn(['token_hash', 'expires_at']);
        });

        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });
    }
};
