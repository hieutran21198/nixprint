{
  namespace,
  lib,
  ...
}:
{
  ${namespace}.agent.skill.skills.asd-ste100-writing = lib.mkDefault {
    description = "Write and review project documentation with ASD-STE100 principles";
    instructions = ''
      Use this skill for new or changed project documentation.
      Read the applicable documentation governance before you write.
      Use ASD-STE100 principles: write short and direct sentences, use one main idea in each sentence, use active voice when possible, use consistent terms, and avoid vague language and unnecessary synonyms.
      Preserve the meaning of requirements when you simplify the language.
      Review the changed documentation for clarity, terminology, and normative terms before completion.
    '';
  };
}
