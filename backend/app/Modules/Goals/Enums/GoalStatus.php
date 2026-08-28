<?php

namespace App\Modules\Goals\Enums;

enum GoalStatus: string
{
    case Active = 'active';
    case Achieved = 'achieved';
    case Abandoned = 'abandoned';
}
