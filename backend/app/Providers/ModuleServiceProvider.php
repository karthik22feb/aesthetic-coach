<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

/**
 * Auto-discovers and registers each domain module's own ServiceProvider,
 * so a new module under app/Modules/* plugs in without editing this class
 * or bootstrap/providers.php -- see docs/07-backend-architecture.md, section 1.
 *
 * A module opts in by defining App\Modules\{Module}\{Module}ServiceProvider.
 * Modules with no provider yet (e.g. a structure-only scaffold) are skipped.
 */
class ModuleServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        foreach ($this->discoverModuleProviders() as $provider) {
            $this->app->register($provider);
        }
    }

    /**
     * @return array<int, class-string<ServiceProvider>>
     */
    protected function discoverModuleProviders(): array
    {
        $modulesPath = app_path('Modules');

        if (! is_dir($modulesPath)) {
            return [];
        }

        $providers = [];

        foreach (scandir($modulesPath) as $module) {
            if ($module === '.' || $module === '..') {
                continue;
            }

            $providerClass = "App\Modules\{$module}\{$module}ServiceProvider";
            $providerPath = $modulesPath.DIRECTORY_SEPARATOR.$module.DIRECTORY_SEPARATOR.$module.'ServiceProvider.php';

            if (is_file($providerPath) && class_exists($providerClass)) {
                $providers[] = $providerClass;
            }
        }

        return $providers;
    }
}
