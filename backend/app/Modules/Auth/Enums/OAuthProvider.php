<?php

namespace App\Modules\Auth\Enums;

enum OAuthProvider: string
{
    case Google = 'google';
    case Apple = 'apple';
}
