== イベントハンドラー<sec_event-handler>
`Solver` のイベントを処理する `EventHandler` トレイトを定義する。
`handle_event()` でイベントを処理する。
```rust
//| id: evh_event-handler-trait
pub trait EventHandler {
    type Event;
    type Error;

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error>;
}
```

```rust
//| file: rust/viska-sat/src/event_handler.rs
<<evh_event-handler-trait>>
```
