<?php

namespace App\Modules\Auth\Http\Resources;

use App\Modules\Auth\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Device
 */
class SessionResource extends JsonResource
{
    public function __construct(Device $resource, protected ?int $currentDeviceId)
    {
        parent::__construct($resource);
    }

    public function toArray(Request $request): array
    {
        return [
            'deviceId' => (string) $this->id,
            'deviceName' => $this->device_name,
            'platform' => $this->platform->value,
            'lastActiveAt' => $this->last_active_at?->toIso8601String(),
            'isCurrent' => $this->id === $this->currentDeviceId,
        ];
    }
}
