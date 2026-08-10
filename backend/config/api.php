<?php

return [

    /*
    |--------------------------------------------------------------------------
    | API Contract Version
    |--------------------------------------------------------------------------
    |
    | Independent of the URI version (/api/v1) -- tracks minor contract
    | revisions, returned in every response. See docs/05-api-specification.md
    | section 1 (Versioning Strategy).
    |
    */

    'version' => env('API_VERSION', '1.0.0'),

];
