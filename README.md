# SLR1-Table-Generator

I have made this for a college project, so I am sharing it.

As the name of the repository already says, given a grammar this code will generate his SLR(1) table, or raise an error.

## Getting Started

### Prerequisites
The code is written in plain ruby, there is no need to install anything but ruby.
The code was only tested with ruby 2.0

### Usage

SLR1 should receive a grammar in the form:

```ruby
{
	'E' => ['E S T', 'T'],
	'S' => ['+', '-'],
	'T' => ['T M F', 'F'],
	'M' => ['*'],
	'F' => ['( E )', 'num', 'epsilon']
}
```
**The first production will be considered the initial production (in the example 'E' =>['E S T', 'T'] )**
