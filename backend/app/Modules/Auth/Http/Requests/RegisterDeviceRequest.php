<?php

namespace App\Modules\Auth\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Sprint 2, Task 8 -- docs/05-api-specification.md section 6.11
 * ("POST /devices | Register device push token"). `pushToken` is the
 * only field this request accepts: `platform`/`deviceName` are already
 * fixed on the device row created at register/login time
 * (AuthService::registerDevice) and aren't re-specified here.
 *
 * max:255 matches the `push_token` column's length
 * (database/migrations/2026_08_07_053332_create_devices_table.php's
 * `$table->string('push_token')` -- Laravel's default string length).
 */
class RegisterDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'pushToken' => ['required', 'string', 'max:255'],
        ];
    }
}
