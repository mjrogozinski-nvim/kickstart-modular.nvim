((function_declarator
  declarator: (identifier) @test.macro
  parameters: (parameter_list
    (parameter_declaration (type_identifier) @fixture.name)
    (parameter_declaration (type_identifier) @test.name)
))
  (#match? @test.macro "^TEST(_F|_P)?$")
)
