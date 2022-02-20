require_relative '../spec_helper'
require_relative '../../lib/rails_monocles'
require_relative '../../lib/monocle/source_updater'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

describe RailsMonocles::Model do
  let(:mutator) { RailsMonocles::Model.new }

  it "should convert dst into ast" do
    result = mutator.dst2code(json_fixture("model_dst.json"))
    assert_equal_ast(read_fixture('post_model.rb'), result)
  end

  it "should convert ast into dst" do
    dst = mutator.code2dst(read_fixture('post_model.rb'))
    assert_equal(json_fixture("model_dst.json"), dst)
  end

  it "should support 'belongs_to' dst" do
    dst = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "belongs_to" } ] }

    fixture = <<~RUBY
      class Post < ApplicationRecord
        belongs_to :author
      end
    RUBY

    result = mutator.dst2code(dst)
    assert_equal_ast(fixture, result)
  end

  it "should support 'belongs_to' ast" do
    dst_fixture = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "belongs_to" } ] }
    source = <<~RUBY
      class Post < ApplicationRecord
        belongs_to :author
      end
    RUBY
    dst = mutator.code2dst(source)
    assert_equal(dst_fixture, dst)
  end

  it "should support 'has_one' dst" do
    dst = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "has_one" } ] }

    fixture = <<~RUBY
      class Post < ApplicationRecord
        has_one :author
      end
    RUBY

    result = mutator.dst2code(dst)
    assert_equal_ast(fixture, result)
  end

  it "should support 'has_one' ast" do
    dst_fixture = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "has_one" } ] }
    source = <<~RUBY
      class Post < ApplicationRecord
        has_one :author
      end
    RUBY
    dst = mutator.code2dst(source)
    assert_equal(dst_fixture, dst)
  end

  it "should support 'has_many' dst" do
    dst = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "has_many" } ] }

    fixture = <<~RUBY
      class Post < ApplicationRecord
        has_many :authors
      end
    RUBY

    result = mutator.dst2code(dst)
    assert_equal_ast(fixture, result)
  end

  it "should support 'has_many' ast" do
    dst_fixture = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "has_many" } ] }
    source = <<~RUBY
      class Post < ApplicationRecord
        has_many :authors
      end
    RUBY
    dst = mutator.code2dst(source)
    assert_equal(dst_fixture, dst)
  end

  it "should support 'has_many :through' dst" do
    dst = { "name" => "Post",
            "associations" => [ { "model" => "author", "type" => "has_many_through", "through" => "contribution" } ] }

    fixture = <<~RUBY
      class Post < ApplicationRecord
        has_many :authors, through: :contributions
      end
    RUBY

    result = mutator.dst2code(dst)
    assert_equal_ast(fixture, result)
  end

  it "should support 'has_many :through' ast" do
    dst_fixture = { "name" => "Post",
                    "associations" => [ { "model" => "author", "type" => "has_many_through", "through" => "contribution" } ] }
    source = <<~RUBY
      class Post < ApplicationRecord
        has_many :authors, through: :contributions
      end
    RUBY
    dst = mutator.code2dst(source)
    assert_equal(dst_fixture, dst)
  end

  it "should support 'has_and_belongs_to_many' dst" do
    dst = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "has_and_belongs_to_many" } ] }

    fixture = <<~RUBY
      class Post < ApplicationRecord
        has_and_belongs_to_many :authors
      end
    RUBY

    result = mutator.dst2code(dst)
    assert_equal_ast(fixture, result)
  end

  it "should support 'has_and_belongs_to_many' ast" do
    dst_fixture = { "name" => "Post", "associations" => [ { "model" => "author", "type" => "has_and_belongs_to_many" } ] }
    source = <<~RUBY
      class Post < ApplicationRecord
        has_and_belongs_to_many :authors
      end
    RUBY
    dst = mutator.code2dst(source)
    assert_equal(dst_fixture, dst)
  end

  it "should convert dst into ast using updater" do
    dst = { "name" => "Post", "associations" => [
      { "model" => "author", "type" => "belongs_to" },
      { "model" => "comment", "type" => "has_many" },
      ]
    }
    code_input = <<~RUBY
      class Post < ApplicationRecord
        belongs_to :author
      end
    RUBY
    fixture = <<~RUBY
      class Post < ApplicationRecord
        belongs_to :author
        has_many :comments
      end
    RUBY
    target = mutator.dst2code(dst)
    code_output = Monocle::SourceUpdater.update(code_input, target)
    assert_equal_ast(fixture, code_output)
  end
end