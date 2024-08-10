import gleam/list
import gleam/string

type CurrentElementType {
  Start
  End
  None
}

fn find_div(in: List(Element)) -> Element {
  case in {
    [] -> EmptyElement
    [StartElement("div", [Attribute("class", "definition")], _) as result, ..] ->
      result
    [_, ..tail] -> find_div(tail)
  }
}

pub type Element {
  EmptyElement
  StartElement(
    name: String,
    attributes: List(Attribute),
    children: List(Element),
  )
  EndElement(name: String)
  Content(String)
}

pub type Attribute {
  Attribute(key: String, value: String)
}

pub fn get_first_element(in: String) -> #(Element, String) {
  in
  |> trim_space_to_elem_begin
  |> do_get_first_element("", None)
}

fn trim_space_to_elem_begin(in: String) -> String {
  case in {
    " " <> remain | "\n" <> remain | "\t" <> remain ->
      trim_space_to_elem_begin(remain)
    "<" <> remain -> "<" <> remain
    _ -> in
  }
}

fn do_get_first_element(
  in: String,
  out: String,
  currently_parsing: CurrentElementType,
) -> #(Element, String) {
  case in {
    "</" <> remain ->
      case out {
        "" -> do_get_first_element(remain, out, End)
        _ -> #(Content(out), "</" <> remain)
      }
    "<" <> remain ->
      case out {
        "" -> do_get_first_element(remain, out, Start)
        _ -> #(Content(out), "<" <> remain)
      }
    ">" <> remain ->
      case currently_parsing {
        Start -> #(StartElement(out, [], []), remain)
        End -> #(EndElement(out), remain)
        None -> #(Content(out), remain)
      }
    " " <> remain | "\n" <> remain | "\t" <> remain
      if currently_parsing == Start
    -> {
      let #(attrs, remain_after_attr) = get_attrs(remain)
      #(StartElement(out, attrs, []), remain_after_attr)
    }
    "" -> #(EmptyElement, "")
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      do_get_first_element(remain, out <> head, currently_parsing)
    }
  }
}

pub fn get_attrs(in: String) -> #(List(Attribute), String) {
  in
  |> trim_space_to_elem_begin
  |> do_get_attrs("", "", False)
}

fn do_get_attrs(
  in: String,
  key: String,
  val: String,
  finding_value: Bool,
) -> #(List(Attribute), String) {
  case in {
    "" | ">" ->
      case key, val {
        "", "" -> #([], "")
        _, "" -> #([], key)
        _, _ -> #([Attribute(key, remove_quotes(val))], "")
      }
    ">" <> remain ->
      case key, val {
        "", "" -> #([], remain)
        _, _ -> #([Attribute(key, remove_quotes(val))], remain)
      }
    " " <> remain | "\n" <> remain | "\t" <> remain if !finding_value ->
      do_get_attrs(remain, key, val, finding_value)
    " " <> remain | "\n" <> remain | "\t" <> remain -> {
      let #(attrs, remain_after_attr) = do_get_attrs(remain, "", "", False)
      #([Attribute(key, remove_quotes(val)), ..attrs], remain_after_attr)
    }
    "=" <> remain -> do_get_attrs(remain, key, "", True)
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      case finding_value {
        True -> do_get_attrs(remain, key, val <> head, finding_value)
        False -> do_get_attrs(remain, key <> head, "", finding_value)
      }
    }
  }
}

fn remove_quotes(in: String) -> String {
  let remove_first_quote = fn(str) {
    case str {
      "\"" <> remain -> remain
      _ -> str
    }
  }

  in
  |> remove_first_quote
  |> string.reverse
  |> remove_first_quote
  |> string.reverse
}

pub fn as_list(in: String) -> List(Element) {
  case in {
    "" -> []
    _ -> {
      let #(first, remain) = get_first_element(in)
      [first, ..as_list(remain)]
    }
  }
}

pub fn as_tree(in: String) -> Element {
  let #(first, remain) = get_first_element(in)
  let #(result, _) = do_as_tree(remain, first)
  result
}

pub fn do_as_tree(in: String, current: Element) -> #(Element, String) {
  let #(next, remain) = get_first_element(in)
  let assert StartElement(cur_name, cur_attrs, cur_children) = current
  case next {
    EndElement(name) if name == cur_name -> #(
      StartElement(cur_name, cur_attrs, cur_children |> list.reverse),
      remain,
    )
    EndElement(_) -> do_as_tree(remain, current)
    _ -> {
      let #(child_tree, remain_after_child) = do_as_tree(remain, next)
      do_as_tree(
        remain_after_child,
        StartElement(cur_name, cur_attrs, [child_tree, ..cur_children]),
      )
    }
  }
}
