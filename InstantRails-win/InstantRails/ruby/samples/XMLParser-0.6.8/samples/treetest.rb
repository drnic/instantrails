#! /usr/local/bin/ruby -Ke

require "xml/dom/core"
include XML::DOM

tree = Document.new(ProcessingInstruction.new("xml",
                                         "version='1.0' encoding='EUC-JP'"),
                    Comment.new("コメント"),
                    Element.new("Test", [
                                  Attr.new('attr1', "属性1"),
                                  Attr.new('attr2', "属性2")],
                                Element.new("para", nil, "こんにちは")))
print tree.to_s, "\n"
tree.dump
