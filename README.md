# Cycromatic

Cycromatic calculates cyclomatic complexity of Ruby programs.

* Cyclomatic Complexity - https://en.wikipedia.org/wiki/Cyclomatic_complexity

## Installation

Install by `gem`:

    $ gem install cycromatic

## Usage

Run `cycromatic` command to calculate complexity:

```
$ cycromatic ruby_program.rb    # Specify paths to .rb files
$ cycromatic app config         # Specify directories including .rb files
```

The output will be like the following:

```
$ cycromatic ../contror/lib/contror/anf/translator.rb
../contror/lib/contror/anf/translator.rb	[toplevel]:1	1
../contror/lib/contror/anf/translator.rb	initialize:8	1
../contror/lib/contror/anf/translator.rb	translate:14	1
../contror/lib/contror/anf/translator.rb	with_new_block:20	3
../contror/lib/contror/anf/translator.rb	current_block:37	1
../contror/lib/contror/anf/translator.rb	push_stmt:41	1
../contror/lib/contror/anf/translator.rb	normalize_node:46	3
../contror/lib/contror/anf/translator.rb	translate0:59	52
../contror/lib/contror/anf/translator.rb	translate_arg:478	3
../contror/lib/contror/anf/translator.rb	translate_call:491	2
../contror/lib/contror/anf/translator.rb	translate_params:533	2
../contror/lib/contror/anf/translator.rb	value_node?:547	7
../contror/lib/contror/anf/translator.rb	fresh_var:566	1
../contror/lib/contror/anf/translator.rb	translate_var:571	5
```

The tool accepts `--format=json` option to output in JSON format.

## Calculation

It calculates complexities as the following:

* Basic block have complexity of 1 (base case)
* Branching construct have complexity of 1
* Loop construct have complexity of 1
* `&&` and `||` have complexity of 1
* Safe navigation operator have complexity of 1
* Passing iterator block does not introduce complexity

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cycromatic.
