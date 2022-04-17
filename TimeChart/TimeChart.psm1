function Get-TimeChartData {
    [CmdletBinding(DefaultParameterSetName = 'ByUsername')]
    param(
        [Parameter(Mandatory, Position=0)]
        [string] $DataDirectory,
        [Parameter(Mandatory = $false, ParameterSetName = 'ByUsername')]
        [string] $Username,
        [Parameter(Mandatory = $false, ParameterSetName = 'ByUsername')]
        [SecureString] $Password,
        [Parameter(Mandatory = $false, ParameterSetName = 'ByCredential')]
        [System.Management.Automation.PSCredential] $Credential

    )

    

    #actual code for the function goes here see the end of the topic for the complete code sample
    if ($Username) {
        if ($Password) {
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
        } else {
            #error
        }
    }

    if (-not $Credential) {
        $Credential = [System.Management.Automation.PSCredential]::Empty
    }

    try {
        New-PSDrive -Name "TimeChart" -PSProvider "FileSystem" -Root $DataDirectory -Credential $Credential -ErrorAction Stop | Out-Null
    } catch {
        exit
    }

    $Students = @()
    if (Test-Path "TimeChart:\STUDENTS.TXT") {
        $Students = Import-Csv -Path "TimeChart:\STUDENTS.TXT" -Header ID, LastName, FirstName, Gender, YearLevel, FormGroup, Status
    }

    $Teachers = @()
    if (Test-Path "TimeChart:\STAFF.TXT") {
        $Teachers = Import-Csv -Path "TimeChart:\STAFF.TXT" -Header ID, FullName
    }

    $ClassesRaw = @()
    if (Test-Path "TimeChart:\SCOURSES.TXT") {
        $ClassesRaw = Import-Csv -Path "TimeChart:\SCOURSES.TXT" -Header StudentID, Code, Code2, Description, TeacherID, YearLevel
    }

    ForEach ($Student in $Students) {
        $Student | Add-Member -NotePropertyName Classes -NotePropertyValue @()
    }

    ForEach ($Teacher in $Teachers) {
        $Teacher | Add-Member -NotePropertyName Classes -NotePropertyValue @()
    }

    $Classes = @()
    ForEach ($ClassRaw in $ClassesRaw) {
        $Student = $Students | Where-Object { $_.ID   -eq $ClassRaw.StudentID}
        $Teacher = $Teachers | Where-Object { $_.ID   -eq $ClassRaw.TeacherID}
        $Class   = $Classes  | Where-Object { $_.Code -eq $ClassRaw.Code}

        if ($Class) {
            if ($Class.Students -notcontains $Student) {
                $Class.Students += $Student
            }

            if ($Class.Teachers -notcontains $Teacher) {
                $Class.Teachers += $Teacher
            }
        } else {
            $Class = [PSCustomObject]@{
                Code        = $ClassRaw.Code.ToUpper();
                Code2       = $ClassRaw.Code2.ToUpper();
                Description = $ClassRaw.Description;
                YearLevel   = $ClassRaw.YearLevel;
                Students    = @($Student);
                Teachers    = @($Teacher)
            }

            $Classes += $Class
        }
    }

    ForEach ($Class in $Classes) {
        ForEach ($Student in $Class.Students) {
            $Student.Classes += $Class
        }
        ForEach ($Teacher in $Class.Teachers) {
            $Teacher.Classes += $Class
        }
    }

    $TimeChartData = [PSCustomObject]@{
        Students = $Students;
        Teachers = $Teachers;
        Classes  = $Classes
    }

    return $TimeChartData

    <#
      .SYNOPSIS
      Gets data from TimeChart CSV/TXT files.

      .DESCRIPTION
      The Get-TimeChartData function reads TimeChart data files and compiles that 
      data into a list of useable powershell objects.

      .PARAMETER DataDirectory
      Specifies the path to TimeChart's "DATA" directory.

      .PARAMETER Username
      (Optional) Specifies a username to use when connecting to the DATA directory.

      .PARAMETER Password
      (Optional) Specifies a password (as a secure string) to use when connecting to the DATA directory.

      .PARAMETER Credential
      (Optional) Specifies a Credential object to use when connecting to the DATA directory.

      .INPUTS
      None. You cannot pipe objects to Get-TimeChartData.

      .OUTPUTS
      A PSCustomObject containing arrays of PSCustomObjects representing Student, Teacher, and Class data from TimeChart.

      .EXAMPLE
      C:\PS> Get-TimeChartData \\M-Server3\TimeChart\DATA

      .EXAMPLE
      C:\PS> $Password = ConvertTo-SecureString "P@ssW0rD!" -AsPlainText -Force
      C:\PS> Get-TimeChartData \\M-Server3\TimeChart\DATA -Username "kurnai\user" -Password $Password

      .EXAMPLE
      C:\PS> $Credential = Get-Credential
      C:\PS> Get-TimeChartData \\M-Server3\TimeChart\DATA -Credential $Credential
    #>
}

Export-ModuleMember -Function Get-TimeChartData