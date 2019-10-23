defmodule JayWayOracle do
  def json_store,
    do: %{
      "store" => %{
        "book" => [
          %{
            "category" => "reference",
            "author" => "Nigel Rees",
            "title" => "Sayings of the Century",
            "price" => 8.95
          },
          %{
            "category" => "fiction",
            "author" => "Evelyn Waugh",
            "title" => "Sword of Honour",
            "price" => 12.99
          },
          %{
            "category" => "fiction",
            "author" => "Herman Melville",
            "title" => "Moby Dick",
            "isbn" => "0-553-21311-3",
            "price" => 8.99
          },
          %{
            "category" => "fiction",
            "author" => "J. R. R. Tolkien",
            "title" => "The Lord of the Rings",
            "isbn" => "0-395-19395-8",
            "price" => 22.99
          }
        ],
        "bicycle" => %{
          "color" => "red",
          "price" => 19.95
        }
      },
      "expensive" => 10
    }

  def scaned_elements,
    do: [
      10,
      %{
        "bicycle" => %{
          "color" => "red",
          "price" => 19.95
        },
        "book" => [
          %{
            "author" => "Nigel Rees",
            "category" => "reference",
            "price" => 8.95,
            "title" => "Sayings of the Century"
          },
          %{
            "author" => "Evelyn Waugh",
            "category" => "fiction",
            "price" => 12.99,
            "title" => "Sword of Honour"
          },
          %{
            "author" => "Herman Melville",
            "category" => "fiction",
            "isbn" => "0-553-21311-3",
            "price" => 8.99,
            "title" => "Moby Dick"
          },
          %{
            "author" => "J. R. R. Tolkien",
            "category" => "fiction",
            "isbn" => "0-395-19395-8",
            "price" => 22.99,
            "title" => "The Lord of the Rings"
          }
        ]
      },
      %{
        "color" => "red",
        "price" => 19.95
      },
      [
        %{
          "author" => "Nigel Rees",
          "category" => "reference",
          "price" => 8.95,
          "title" => "Sayings of the Century"
        },
        %{
          "author" => "Evelyn Waugh",
          "category" => "fiction",
          "price" => 12.99,
          "title" => "Sword of Honour"
        },
        %{
          "author" => "Herman Melville",
          "category" => "fiction",
          "isbn" => "0-553-21311-3",
          "price" => 8.99,
          "title" => "Moby Dick"
        },
        %{
          "author" => "J. R. R. Tolkien",
          "category" => "fiction",
          "isbn" => "0-395-19395-8",
          "price" => 22.99,
          "title" => "The Lord of the Rings"
        }
      ],
      "red",
      19.95,
      %{
        "author" => "Nigel Rees",
        "category" => "reference",
        "price" => 8.95,
        "title" => "Sayings of the Century"
      },
      %{
        "author" => "Evelyn Waugh",
        "category" => "fiction",
        "price" => 12.99,
        "title" => "Sword of Honour"
      },
      %{
        "author" => "Herman Melville",
        "category" => "fiction",
        "isbn" => "0-553-21311-3",
        "price" => 8.99,
        "title" => "Moby Dick"
      },
      %{
        "author" => "J. R. R. Tolkien",
        "category" => "fiction",
        "isbn" => "0-395-19395-8",
        "price" => 22.99,
        "title" => "The Lord of the Rings"
      },
      "Nigel Rees",
      "reference",
      8.95,
      "Sayings of the Century",
      "Evelyn Waugh",
      "fiction",
      12.99,
      "Sword of Honour",
      "Herman Melville",
      "fiction",
      "0-553-21311-3",
      8.99,
      "Moby Dick",
      "J. R. R. Tolkien",
      "fiction",
      "0-395-19395-8",
      22.99,
      "The Lord of the Rings"
    ]

  def scaned_paths,
    do: [
      "$['expensive']",
      "$['store']",
      "$['store']['bicycle']",
      "$['store']['book']",
      "$['store']['bicycle']['color']",
      "$['store']['bicycle']['price']",
      "$['store']['book'][0]",
      "$['store']['book'][1]",
      "$['store']['book'][2]",
      "$['store']['book'][3]",
      "$['store']['book'][0]['author']",
      "$['store']['book'][0]['category']",
      "$['store']['book'][0]['price']",
      "$['store']['book'][0]['title']",
      "$['store']['book'][1]['author']",
      "$['store']['book'][1]['category']",
      "$['store']['book'][1]['price']",
      "$['store']['book'][1]['title']",
      "$['store']['book'][2]['author']",
      "$['store']['book'][2]['category']",
      "$['store']['book'][2]['isbn']",
      "$['store']['book'][2]['price']",
      "$['store']['book'][2]['title']",
      "$['store']['book'][3]['author']",
      "$['store']['book'][3]['category']",
      "$['store']['book'][3]['isbn']",
      "$['store']['book'][3]['price']",
      "$['store']['book'][3]['title']"
    ]
end
