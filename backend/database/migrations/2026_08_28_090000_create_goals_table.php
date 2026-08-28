<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['strength', 'body_composition', 'habit', 'event']);
            $table->string('title', 150);
            $table->string('target_metric', 60)->nullable();
            $table->decimal('target_value', 8, 2)->nullable();
            $table->date('target_date')->nullable();
            $table->enum('status', ['active', 'achieved', 'abandoned'])->default('active');
            $table->timestamp('created_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};
