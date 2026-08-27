<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds the profile columns from the frozen Database Design section 3.1
 * `users` table spec that the original auth-foundation migration
 * deliberately deferred (it scoped `users` to auth-relevant columns only --
 * see the 2026-08-10 DEVELOPMENT_LOG.md entry). Purely additive
 * (nullable/defaulted), per the expand/contract migration policy in
 * docs/04-database-design.md section 6 -- no backfill needed since every
 * new column has a safe default or is nullable.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('timezone', 64)->default('UTC')->after('password_hash');
            $table->enum('unit_preference', ['metric', 'imperial'])->default('metric')->after('timezone');
            $table->date('date_of_birth')->nullable()->after('unit_preference');
            $table->enum('sex', ['male', 'female', 'unspecified'])->nullable()->after('date_of_birth');
            $table->decimal('height_cm', 5, 2)->nullable()->after('sex');
            $table->json('dietary_restrictions')->nullable()->after('height_cm');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'timezone',
                'unit_preference',
                'date_of_birth',
                'sex',
                'height_cm',
                'dietary_restrictions',
            ]);
        });
    }
};
