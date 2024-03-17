defmodule GeneticString do
  @target_phrase "Hello Elixir"

  def possible_characters() do
    Enum.to_list(?a..?z) ++
      Enum.to_list(?A..?Z) ++
      [?_, ?\s]
  end

  # Generate a random chromosome (potential solution)
  def random_chromosome() do
    Enum.map(
      1..String.length(@target_phrase),
      fn _ -> possible_characters() |> Enum.random() end
    )
    |> List.to_string()
  end

  def fitness(chromosome, memo \\ %{}) do
    case Map.get(memo, chromosome) do
      nil ->
        fitness = fitness_calc(chromosome)
        updated_memo = Map.put(memo, chromosome, fitness)
        {fitness, updated_memo}

      fitness ->
        {fitness, memo}
    end
  end

  def fitness_calc(chromosome) do
    chromosome
    |> String.graphemes()
    |> Enum.zip(String.graphemes(@target_phrase))
    |> Enum.count(fn {char1, char2} -> char1 == char2 end)
  end

  def memoize_fitness([], memo), do: memo

  def memoize_fitness([chromosome | tail], memo) do
    {_, new_memo} = fitness(chromosome, memo)
    memoize_fitness(tail, new_memo)
  end

  def select_parents([]), do: []

  def select_parents(population) do
    population
    |> Enum.shuffle()
    |> Enum.take(2)
  end

  def crossover(chromosome1, chromosome2) do
    crossover_point = Enum.random(1..(String.length(chromosome1) - 1))

    String.slice(chromosome1, 0, crossover_point) <>
      String.slice(chromosome2, crossover_point, String.length(chromosome2) - crossover_point)
  end

  def mutation(chromosome) do
    mutation_point = Enum.random(0..(String.length(chromosome) - 1))

    String.slice(chromosome, 0, mutation_point) <>
      List.to_string([possible_characters() |> Enum.random()]) <>
      String.slice(
        chromosome,
        mutation_point + 1,
        String.length(chromosome) - (mutation_point + 1)
      )
  end

  def evolve(population_size, generation_limit \\ 100) do
    population = Enum.map(1..population_size, fn _ -> random_chromosome() end)
    elitism_rate = 0.01

    evolve_mechanism(
      %{i: 0, limit: generation_limit},
      %{population: population, size: population_size},
      %{rate: elitism_rate, count: floor(elitism_rate * population_size)},
      %{}
    )
  end

  def evolve_mechanism(generation, %{population: [best_match | _]}, _elitism, _fitness_memo)
      when generation.limit == generation.i,
      do: %{chromosome: best_match, generation: generation.i}

  def evolve_mechanism(generation, population_data, elitism, fitness_memo) do
    memoized_fitness = memoize_fitness(population_data.population, fitness_memo)

    sorted_population =
      population_data.population
      |> Enum.sort_by(fn chromosome -> Map.get(memoized_fitness, chromosome) end, :desc)

    elite_population =
      sorted_population
      |> Enum.take(elitism.count)

    rest_population = Enum.drop(sorted_population, elitism.count) |> Enum.shuffle()

    possible_parents =
      case length(elite_population) do
        x when x < 2 -> elite_population ++ Enum.take(sorted_population, 2)
        _ -> elite_population
      end

    [parent1, parent2] = select_parents(possible_parents)
    offspring = crossover(parent1, parent2) |> mutation()

    # Keep an elite-num of chromosome, and drop less fortunate chromomse before appending the offspring
    new_population =
      (elite_population ++ rest_population)
      |> Enum.drop(-1)
      |> Kernel.++([offspring])

    [elite | _] = new_population
    fitness_score = Map.get(memoized_fitness, elite)
    max_score = String.length(@target_phrase)

    case fitness_score do
      x when x == max_score ->
        %{chromosome: elite, generation: generation.i}

      _ ->
        evolve_mechanism(
          %{i: generation.i + 1, limit: generation.limit},
          %{population: new_population, size: population_data.size},
          adjust_elitism(elitism, generation, population_data.size),
          # elitism,
          memoized_fitness
        )
    end
  end

  def adjust_elitism(elitism, generation, population_size) do
    progress = generation.i / generation.limit

    rate =
      case progress do
        # Promote better fits in earlier generations
        x when x < 0.5 ->
          max(elitism.rate - 0.05, 0.01)

        # Promote more diversity in later generations
        _ ->
          min(elitism.rate + 0.01, 0.25)
      end

    %{rate: rate, count: floor(rate * population_size)}
  end
end
