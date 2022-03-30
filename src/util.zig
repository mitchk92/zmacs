pub const Pos = struct {
    row: usize,
    col: usize,
};

pub const Rect = struct {
    pos: Pos,
    size: Pos,
};
