import gleam/list
import gleeunit
import gleeunit/should
import html_parser

pub fn main() {
  gleeunit.main()
}

pub fn get_first_element_test() {
  let tests = [
    #("empty string", "", #(html_parser.EmptyElement, "")),
    #("div", "<div>", #(html_parser.StartElement("div", []), "")),
    #("end div", "</div>", #(html_parser.EndElement("div"), "")),
    #("end div with leading spaces", "     </div>", #(
      html_parser.EndElement("div"),
      "",
    )),
    #("div with leading spaces", "   <div>", #(
      html_parser.StartElement("div", []),
      "",
    )),
    #("div with internal spaces", "<div  >", #(
      html_parser.StartElement("div", []),
      "",
    )),
    #("div with remaining", "<div>  <div>", #(
      html_parser.StartElement("div", []),
      "  <div>",
    )),
  ]

  list.each(tests, fn(testcase) {
    let #(_, in, expected) = testcase
    html_parser.get_first_element(in) |> should.equal(expected)
  })
}

pub fn get_attrs_test() {
  let tests = [
    #("empty string", "", [html_parser.Attribute("", "")]),
    #("single simple attr", "a=b", [html_parser.Attribute("a", "b")]),
    #("surrounding spaces", "     a=b", [html_parser.Attribute("a", "b")]),
    #("single larger attr", "aaaaaaa=bbbbbb", [
      html_parser.Attribute("aaaaaaa", "bbbbbb"),
    ]),
    #("multiple simple attr", "a=b c=d e=f", [
      html_parser.Attribute("a", "b"),
      html_parser.Attribute("c", "d"),
      html_parser.Attribute("e", "f"),
    ]),
    #("multiple larger attr", "aaaaaaa=bbbbbb ccc=dddd", [
      html_parser.Attribute("aaaaaaa", "bbbbbb"),
      html_parser.Attribute("ccc", "dddd"),
    ]),
  ]

  list.each(tests, fn(testcase) {
    let #(_, in, expected) = testcase
    html_parser.get_attrs(in) |> should.equal(expected)
  })
}
