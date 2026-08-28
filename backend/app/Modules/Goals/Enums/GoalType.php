<?php

namespace App\Modules\Goals\Enums;

enum GoalType: string
{
    case Strength = 'strength';
    case BodyComposition = 'body_composition';
    case Habit = 'habit';
    case Event = 'event';
}
