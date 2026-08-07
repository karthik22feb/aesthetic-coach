<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event to listener mappings for the application.
     *
     * Populated per module as each module's events/listeners are implemented
     * (see docs/07-backend-architecture.md, section 5 Events).
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [];
}
