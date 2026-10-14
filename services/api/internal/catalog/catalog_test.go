package catalog

import "testing"

func testSchema(t *testing.T) *Schema {
	t.Helper()
	c, err := Embedded()
	if err != nil {
		t.Fatal(err)
	}
	s := &Schema{Groups: c.Groups, Attrs: c.Attributes, byKey: map[string]*Attribute{}}
	for i := range s.Attrs {
		s.byKey[s.Attrs[i].Key] = &s.Attrs[i]
	}
	return s
}

func TestEmbeddedCatalog(t *testing.T) {
	c, err := Embedded()
	if err != nil {
		t.Fatal(err)
	}
	if len(c.Attributes) < 60 {
		t.Fatalf("plan requires at least 60 attributes, have %d", len(c.Attributes))
	}
	types := map[string]bool{}
	for _, a := range c.Attributes {
		types[a.Type] = true
	}
	for _, want := range []string{"bool", "int", "range", "enum", "set"} {
		if !types[want] {
			t.Errorf("no attribute of type %s", want)
		}
	}
}

func TestValidate(t *testing.T) {
	s := testSchema(t)
	out, errs := s.Validate(map[string]any{
		"balcony": true, "layout": "2+kk", "floor_area": 54.5, "floor": 3.0,
		"pets": []any{"dogs", "cats", "dogs"}, "elevator": nil,
	}, "apartment")
	if len(errs) != 0 {
		t.Fatalf("unexpected errors %v", errs)
	}
	if got := out["pets"].([]string); len(got) != 2 || got[0] != "cats" {
		t.Fatalf("set not normalized: %v", got)
	}
	if _, ok := out["elevator"]; ok {
		t.Fatal("null should remove the attribute")
	}
	_, errs = s.Validate(map[string]any{
		"layout": "9+9", "floor": 2.5, "balcony": "yes", "nope": 1.0, "room_lockable": true, "floor_area": 1e9,
	}, "apartment")
	if len(errs) != 6 {
		t.Fatalf("want 6 errors, got %v", errs)
	}
	if _, errs := s.Validate(map[string]any{"room_lockable": true}, "room"); len(errs) != 0 {
		t.Fatalf("room attribute rejected for room: %v", errs)
	}
}
