[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# ZEN Rules Engine for Ruby (ALPHA)

Ruby Bindings for the [GoRules Zen Business Rules Engine](https://github.com/gorules/zen).

ZEN Engine is a cross-platform, Open-Source Business Rules Engine (BRE). It is written in Rust and provides native 
bindings for **Ruby**, **NodeJS**, **Python**, **Ruby**, and **Go**. ZEN Engine allows to load and execute JSON Decision Model (JDM) from JSON files.

<img width="800" alt="Open-Source Rules Engine" src="https://gorules.io/images/jdm-editor.gif">

An open-source React editor is available on our [JDM Editor](https://github.com/gorules/jdm-editor) repo.

## Installation

```bash
gem install zen-engine-ruby
```

Or add `zen-engine-ruby` to your `Gemfile`.

## Usage

ZEN Engine is built as embeddable BRE for your **Ruby**, **Rust**, **NodeJS**, **Python** or **Go** applications.
It parses JDM from JSON content. It is up to you to obtain the JSON content, e.g. from file system, database or service call.

### Load and Execute Rules

TODO: write this section. In the meantime, take a look at [test.rb](./test.rb) for how to use this API.

### Supported Platforms

List of platforms where Zen Engine is natively available:

* **Ruby** - [GitHub](https://github.com/FutureProofRetail/zen-engine-ruby/README.md)
* **NodeJS** - [GitHub](https://github.com/gorules/zen/blob/master/bindings/nodejs/README.md) | [Documentation](https://gorules.io/docs/developers/bre/engines/nodejs) | [npmjs](https://www.npmjs.com/package/@gorules/zen-engine)
* **Python** - [GitHub](https://github.com/gorules/zen/blob/master/bindings/python/README.md) | [Documentation](https://gorules.io/docs/developers/bre/engines/python) | [pypi](https://pypi.org/project/zen-engine/)
* **Go** - [GitHub](https://github.com/gorules/zen-go) | [Documentation](https://gorules.io/docs/developers/bre/engines/go)
* **Rust (Core)** - [GitHub](https://github.com/gorules/zen) | [Documentation](https://gorules.io/docs/developers/bre/engines/rust) | [crates.io](https://crates.io/crates/zen-engine)

For a complete **Business Rules Management Systems (BRMS)** solution:

* [Self-hosted BRMS](https://gorules.io)
* [GoRules Cloud BRMS](https://gorules.io/signin/verify-email)

## JSON Decision Model (JDM)

GoRules JDM (JSON Decision Model) is a modeling framework designed to streamline the representation and implementation
of decision models.

#### Understanding GoRules JDM

At its core, GoRules JDM revolves around the concept of decision models as interconnected graphs stored in JSON format.
These graphs capture the intricate relationships between various decision points, conditions, and outcomes in a GoRules
Zen-Engine.

Graphs are made by linking nodes with edges, which act like pathways for moving information from one node to another,
usually from the left to the right.

The Input node serves as an entry for all data relevant to the context, while the Output nodes produce the result of
decision-making process. The progression of data follows a path from the Input Node to the Output Node, traversing all
interconnected nodes in between. As the data flows through this network, it undergoes evaluation at each node, and
connections determine where the data is passed along the graph.

To see JDM Graph in action you can use [Free Online Editor](https://editor.gorules.io) with built in Simulator.

There are 5 main node types in addition to a graph Input Node (Request) and Output Node (Response):

* Decision Table Node
* Switch Node
* Function Node
* Expression Node
* Decision Node

### Decision Table Node

#### Overview

Tables provide a structured representation of decision-making processes, allowing developers and business users to
express complex rules in a clear and concise manner.

<img width="960" alt="Decision Table" src="https://gorules.io/images/decision-table.png">

#### Structure

At the core of the Decision Table is its schema, defining the structure with inputs and outputs. Inputs encompass
business-friendly expressions using the ZEN Expression Language, accommodating a range of conditions such as equality,
numeric comparisons, boolean values, date time functions, array functions and more. The schema's outputs dictate the
form of results generated by the Decision Table.
Inputs and outputs are expressed through a user-friendly interface, often resembling a spreadsheet. This facilitates
easy modification and addition of rules, enabling business users to contribute to decision logic without delving into
intricate code.

#### Evaluation Process

Decision Tables are evaluated row by row, from top to bottom, adhering to a specified hit policy.
Single row is evaluated via Inputs columns, from left to right. Each input column represents `AND` operator. If cell is
empty that column is evaluated **truthfully**, independently of the value.

If a single cell within a row fails (due to error, or otherwise), the row is skipped.

**HitPolicy**

The hit policy determines the outcome calculation based on matching rules.

The result of the evaluation is:

* **an object** if the hit policy of the decision table is `first` and a rule matched. The structure is defined by the
  output fields. Qualified field names with a dot (.) inside lead to nested objects.
* **`null`/`undefined`** if no rule matched in `first` hit policy
* **an array of objects** if the hit policy of the decision table is `collect` (one array item for each matching rule)
  or empty array if no rules match

#### Inputs

In the assessment of rules or rows, input columns embody the `AND` operator. The values typically consist of (qualified)
names, such as `customer.country` or `customer.age`.

There are two types of evaluation of inputs, `Unary` and `Expression`.

**Unary Evaluation**

Unary evaluation is usually used when we would like to compare single fields from incoming context separately, for
example `customer.country` and `cart.total` . It is activated when a column has `field` defined in its schema.

***Example***

For the input:

```json
{
  "customer": {
    "country": "US"
  },
  "cart": {
    "total": 1500
  }
}
```

<img width="960" alt="Decision Table Unary Test" src="https://gorules.io/images/decision-table.png">

This evaluation translates to

```
IF customer.country == 'US' AND cart.total > 1000 THEN {"fees": {"percent": 2}}
ELSE IF customer.country == 'US' THEN {"fees": {"flat": 30}}
ELSE IF customer.country == 'CA' OR customer.country == 'MX' THEN {"fees": {"flat": 50}}
ELSE {"fees": {"flat": 150}}
```

List shows basic example of the unary tests in the Input Fields:

| Input entry | Input Expression                               |
|-------------|------------------------------------------------|
| "A"         | the field equals "A"                           |
| "A", "B"    | the field is either "A" or "B"                 |
| 36          | the numeric value equals 36                    |
| < 36        | a value less than 36                           |
| > 36        | a value greater than 36                        |
| [20..39]    | a value between 20 and 39 (inclusive)          |
| 20,39       | a value either 20 or 39                        |
| <20, >39    | a value either less than 20 or greater than 39 |
| true        | the boolean value true                         |
| false       | the boolean value false                        |
|             | any value, even null/undefined                 |
| null        | the value null or undefined                    |

Note: For the full list please
visit [ZEN Expression Language](https://gorules.io/docs/rules-engine/expression-language/).

**Expression Evaluation**

Expression evaluation is used when we would like to create more complex evaluation logic inside single cell. It allows
us to compare multiple fields from the incoming context inside same cell.

It can be used by providing an empty `Selector (field)` inside column configuration.

***Example***

For the input:

```json
{
  "transaction": {
    "country": "US",
    "createdAt": "2023-11-20T19:00:25Z",
    "amount": 10000
  }
}
```

<img width="960" alt="Decision Table Expression" src="https://gorules.io/images/decision-table-expression.png">

```
IF time(transaction.createdAt) > time("17:00:00") AND transaction.amount > 1000 THEN {"status": "reject"}
ELSE {"status": "approve"}
```

Note: For the full list please
visit [ZEN Expression Language](https://gorules.io/docs/rules-engine/expression-language/).

**Outputs**

Output columns serve as the blueprint for the data that the decision table will generate when the conditions are met
during evaluation.

When a row in the decision table satisfies its specified conditions, the output columns determine the nature and
structure of the information that will be returned. Each output column represents a distinct field, and the collective
set of these fields forms the output or result associated with the validated row. This mechanism allows decision tables
to precisely define and control the data output.

***Example***

<img width="860" alt="Decision Table Output" src="https://gorules.io/images/decision-table-output.png">

And the result would be:

```json
{
  "flatProperty": "A",
  "output": {
    "nested": {
      "property": "B"
    },
    "property": 36
  }
}
```

### Switch Node (NEW)

The Switch node in GoRules JDM introduces a dynamic branching mechanism to decision models, enabling the graph to
diverge based on conditions.

Conditions are written in a Zen Expression Language.

By incorporating the Switch node, decision models become more flexible and context-aware. This capability is
particularly valuable in scenarios where diverse decision logic is required based on varying inputs. The Switch node
efficiently manages branching within the graph, enhancing the overall complexity and realism of decision models in
GoRules JDM, making it a pivotal component for crafting intelligent and adaptive systems.

The Switch node preserves the incoming data without modification; it forwards the entire context to the output branch(
es).

<img width="960" alt="Switch / Branching" src="https://gorules.io/images/decision-graph.png">

#### HitPolicy

There are two HitPolicy options for the switch node, `first` and `collect`.

In the context of a first hit policy, the graph branches to the initial matching condition, analogous to the behavior
observed in a table. Conversely, under a collect hit policy, the graph extends to all branches where conditions hold
true, allowing branching to multiple paths.

Note: If there are multiple edges from the same condition, there is no guaranteed order of execution.

*Available from:*

* Python 0.16.0
* NodeJS 0.13.0
* Rust 0.16.0
* Go 0.1.0

### Functions Node

Function nodes are JavaScript snippets that allow for quick and easy parsing, re-mapping or otherwise modifying the data
using JavaScript. Inputs of the node are provided as function's arguments. Functions are executed on top of QuickJS
Engine that is bundled into the ZEN Engine.

Function timeout is set to a 50ms.

```js
const handler = (input, {dayjs, Big}) => {
    return {
        ...input,
        someField: 'hello'
    };
};
```

There are two built in libraries:

* [dayjs](https://www.npmjs.com/package/dayjs) - for Date Manipulation
* [big.js](https://www.npmjs.com/package/big.js) - for arbitrary-precision decimal arithmetic.

### Expression Node

The Expression node serves as a tool for transforming input objects into alternative objects using the Zen Expression
Language. When specifying the output properties, each property requires a separate row. These rows are defined by two
fields:

- Key - qualified name of the output property
- Value - value expressed through the Zen Expression Language

Note: Any errors within the Expression node will bring the graph to a halt.

<img width="960" alt="Decision Table" src="https://gorules.io/images/expression.png">

### Decision Node

The "Decision" node is designed to extend the capabilities of decision models. Its function is to invoke and reuse other
decision models during execution.

By incorporating the "Decision" node, developers can modularize decision logic, promoting reusability and
maintainability in complex systems.

## Support matrix

| Arch            | Rust               | NodeJS             | Python             | Go                 |
|:----------------|:-------------------|:-------------------|:-------------------|:-------------------|
| linux-x64-gnu   | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| linux-arm64-gnu | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| darwin-x64      | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| darwin-arm64    | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| win32-x64-msvc  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |

We do not support linux-musl currently.

## Contribution

JDM standard is growing and we need to keep tight control over its development and roadmap as there are number of
companies that are using GoRules Zen-Engine and GoRules BRMS.
For this reason we can't accept any code contributions at this moment, apart from help with documentation and additional
tests.

## License

[MIT License]()

