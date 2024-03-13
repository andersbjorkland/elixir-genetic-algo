defmodule GeneticStringTest do
  use ExUnit.Case

  @target_phrase "Hello Elixir"

  test "possible_characters/0 generates the expected set and length" do
    valid_characters = ~r/[a-zA-Z_\s]/

    result = GeneticString.possible_characters() |> List.to_string()

    assert Regex.match?(valid_characters, result)
  end

  test "random_chromosome/0 has correct length and characters" do
    chromosome = GeneticString.random_chromosome()

    assert String.length(chromosome) == String.length(@target_phrase)

    chromosome
    |> String.to_charlist()
    |> Enum.each(fn char ->
      assert char in GeneticString.possible_characters()
    end)
  end

  test "fitness_calc/1 do the correct calculations" do
    input_output = %{
      "Hello Elixir" => 12,
      "000000000000" => 0,
      "H0000_E00000" => 2,
      "0ellO E000ir" => 7,
      "hello0000000" => 4,
      "" => 0,
      "00000000000000000" => 0
    }

    Enum.each(input_output, fn {input, expected_output} ->
      result = GeneticString.fitness_calc(input)
      assert result == expected_output, "Expected #{result} to be #{expected_output}"
    end)
  end

  test "memoize_fitness stores and retrieves fitness scores" do
    chromosome1 = "Some string"
    chromosome2 = "Heyo string"

    # First call should calculate fitness
    {fitness1, memo1} = GeneticString.fitness(chromosome1)

    {_fitness2, memo2} = GeneticString.fitness(chromosome2, memo1)

    # Third call should use memoized value
    {fitness3, memo3} = GeneticString.fitness(chromosome1, memo2)

    assert fitness1 == fitness3
    # Memo should be updated
    assert memo1 != memo3
  end

  test "crossover has genes from both parents" do
    parent1 = "HELLO world"
    parent2 = "????? ??????"

    offspring = GeneticString.crossover(parent1, parent2)

    [result1 | _] = String.split(offspring, "?")
    [_ | [result2 | _]] = String.split(offspring, result1)

    {_, match1_length} = :binary.match(parent1, result1)
    {_, match2_length} = :binary.match(parent2, result2)

    assert match1_length > 1
    assert match2_length > 1
  end
end
