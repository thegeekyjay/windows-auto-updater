@{
    # Rules to include/exclude or change severity. See PSScriptAnalyzer docs for rule names.
    Rules = @(
        @{ Name = 'PSAvoidUsingPlainTextForPassword'; Severity = 'Error' },
        @{ Name = 'PSUseDeclaredVarsMoreThanAssignments'; Severity = 'Warning' },
        @{ Name = 'PSAvoidGlobalVars'; Severity = 'Warning' }
    )

    IncludeRules = @(
        'PSAvoidUsingPlainTextForPassword',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidGlobalVars'
    )

    ExcludeRules = @(
        # Some rules may be noisy for scripting projects; disable as needed
        'PSAvoidUsingConvertToSecureStringWithPlainText',
    )
}
