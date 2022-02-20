#!/usr/bin/env ruby
# coding: utf-8
# class preceeding
# another class preceeding
class Foo # class keyword line
  # method foo preceeding
  def baz
    # in foo
    puts 'foo'
  end # method foo decorating
  # method bar preceeding
  def bar
    # expression preceeding
    1 + # 1 decorating
      2
    # method bar sparse
  end # method bar decorating
  # class sparse
end # class decorating