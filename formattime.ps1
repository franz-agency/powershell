# this script is used to format the time in a readable format

function Format-TimeSpan([TimeSpan]$timeSpan, [string]$taskName = "This task")
{
    if ($timeSpan.TotalSeconds -lt 1)
    {
        # Output the duration in milliseconds if it's less than 1 second
        return "$taskName took $( $timeSpan.Milliseconds ) milliseconds to complete."
    }
    elseif ($timeSpan.TotalHours -ge 1)
    {
        # Output the duration in hours, minutes, and seconds if it's 1 hour or more
        $hourString = "hour"
        if ($timeSpan.Hours -gt 1)
        {
            $hourString += "s"
        }
        if ($timeSpan.Minutes -gt 0)
        {
            return "$taskName took $( $timeSpan.Hours ) $hourString, $( $timeSpan.Minutes ) minute(s), and $( $timeSpan.Seconds ) second(s) to complete."
        }
        else
        {
            return "$taskName took $( $timeSpan.Hours ) $hourString and $( $timeSpan.Seconds ) second(s) to complete."
        }
    }
    elseif ($timeSpan.TotalMinutes -ge 1)
    {
        # Output the duration in minutes and seconds if it's 1 minute or more
        $minuteString = "minute"
        if ($timeSpan.Minutes -gt 1)
        {
            $minuteString += "s"
        }
        return "$taskName took $( $timeSpan.Minutes ) $minuteString and $( $timeSpan.Seconds ) second(s) to complete."
    }
    else
    {
        # Output the duration in seconds if it's less than 1 minute
        return "$taskName took $( $timeSpan.Seconds ) second(s) to complete."
    }
}

# Measure the time and save it in $time
$time = Measure-Command {
    # wait for a random amount of time, max 2 minutes
    Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum 120000)
}

# Convert the measured time into a TimeSpan instance
$timeSpan = [TimeSpan]::FromSeconds($time.TotalSeconds)

# Call the function to generate the formatted output
$durationString = Format-TimeSpan $timeSpan -taskName "The waiting"

# Output the duration string
Write-Host $durationString
 #>