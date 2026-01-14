((normal_command (identifier) @function.name
                 (argument_list
                  .
                  (argument
                    (unquoted_argument) @target.name)
                  .
                  (_)))
  (#eq? @function.name "add_executable")
)

((normal_command (identifier) @function.name
                 (argument_list
                  .
                  (argument
                    (unquoted_argument) @target.name)
                  .
                  (_)))
  (#eq? @function.name "add_library")
)
