<?php

namespace App\Modules\Auth\Enums;

/**
 * Used only for DFS/nutrition baseline calculations, per
 * docs/04-database-design.md section 3.1.
 */
enum Sex: string
{
    case Male = 'male';
    case Female = 'female';
    case Unspecified = 'unspecified';
}
