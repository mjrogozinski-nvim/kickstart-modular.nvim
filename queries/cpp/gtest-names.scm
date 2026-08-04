(
  (function_definition
    declarator: (function_declarator
      declarator: (identifier) @test.macro
      parameters: (parameter_list
        (parameter_declaration (type_identifier) @test.suite)
        (parameter_declaration (type_identifier) @test.name)))) @test.definition
  (#any-of? @test.macro "TEST" "TEST_F" "TEST_P")
)

(
  [
    (class_specifier
      name: (type_identifier) @fixture.name
      (base_class_clause
        [
          (type_identifier)
          (qualified_identifier)
          (template_type)
        ] @fixture.base))
    (struct_specifier
      name: (type_identifier) @fixture.name
      (base_class_clause
        [
          (type_identifier)
          (qualified_identifier)
          (template_type)
        ] @fixture.base))
  ] @fixture.definition
)
