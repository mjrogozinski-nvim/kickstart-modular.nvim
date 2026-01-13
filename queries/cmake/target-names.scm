((normal_command (identifier) @function.name
                (argument_list
                  (argument
                    (unquoted_argument) @target.name)
                  (_)))
  (#match? @function.name "^add_executable|add_library$")
)
