// ~/~ begin <<rust/viska-sat/src/event_handler.typ#rust/viska-sat/src/event_handler.rs>>[init]
//| file: rust/viska-sat/src/event_handler.rs
// ~/~ begin <<rust/viska-sat/src/solver.typ#evh_event-handler-trait>>[init]
//| id: evh_event-handler-trait
pub trait EventHandler {
    type Event;
    type Error;

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error>;
}
// ~/~ end
// ~/~ end
