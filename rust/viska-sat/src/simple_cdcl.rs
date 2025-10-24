// ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#rust/viska-sat/src/simple_cdcl.rs>>[init]
//| file: rust/viska-sat/src/simple_cdcl.rs
use crate::{assignment::Assignment, clause::{Clause, ClauseState}, cnf::Cnf, event_handler::EventHandler, lit::Lit, solver::{SatResult, Solver}};
use std::collections::HashSet;

#[derive(Debug)]
pub enum SimpleCdclSolverEvent {
    Decide {idx: usize, assign: bool},
    Propagate {idx: usize, assign: bool, reason: usize},
    Conflict {reason: usize},
    Resolve {lit: Lit, reason_clause_id: usize, learnt_clause: Clause},
    LearntClause {clause: Clause},
    RootConflict,
    BacktrackTo {level: usize},
    Finish {result: SatResult}
}

// ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_trail>>[init]
//| id: scdcl_trail
// ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_step>>[init]
//| id: scdcl_step
#[derive(Clone)]
enum AssignmentReason {
    Decision,
    UnitPropagation{clause_id: usize}
}

struct Step {
    lit: Lit,
    decision_level: usize,
    reason: AssignmentReason
}
// ~/~ end

struct Trail {
    trail: Vec<Step>,
    assign: Assignment,
    decision_levels: Vec<Option<usize>>,
    current_decision_level: usize,
}

impl Trail {
    // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_push-step>>[init]
    //| id: scdcl_push-step
    fn push_step(&mut self, lit: Lit, reason: AssignmentReason) {
        if matches!(reason, AssignmentReason::Decision) {
            self.current_decision_level += 1;
        }
        let var_id = lit.var_id;
        self.assign.values[var_id] = Some(!lit.negated);
        self.decision_levels[var_id] = Some(self.current_decision_level);
        self.trail.push(Step {
            decision_level: self.current_decision_level,
            lit,
            reason
        });
    }
    // ~/~ end
    // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_trail-backtrack>>[init]
    //| id: scdcl_trail-backtrack
    fn backtrack(&mut self, level: usize) {
        while let Some(step) = self.trail.last() {
            if step.decision_level <= level {
                break;
            }

            let var_id = step.lit.var_id;
            self.assign.values[var_id] = None;
            self.decision_levels[var_id] = None;
            self.trail.pop();
        }
        self.current_decision_level = level;
    }
    // ~/~ end
}
// ~/~ end

pub struct SimpleCdclSolver<H> 
{
    pub cnf: Cnf,
    pub handler: H
}

impl<H> SimpleCdclSolver<H>
where
    H: EventHandler<Event = SimpleCdclSolverEvent>
{
    // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_pick-unassigned-var>>[init]
    //| id: dpll_pick-unassigned-var
    fn pick_unassigned_var(&self, assign: &Assignment) -> Option<usize> {
        for i in 0..assign.values.len() {
            if assign.values[i].is_none() {
                return Some(i);
            }
        }
        return None;
    }
    // ~/~ end

    // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_repeat-unit-propagation>>[init]
    //| id: scdcl_repeat-unit-propagation
    fn repeat_unit_propagate(
        &mut self,
        trail: &mut Trail,
    ) -> Result<Option<usize>, H::Error> {
        'outer: loop {
            for (clause_id, clause) in self.cnf.clauses.iter().enumerate() {
                match clause.eval(&trail.assign) {
                    ClauseState::Unit(lit) => {
                        let idx = lit.var_id;
                        let val = !lit.negated;
                        self.handler.handle_event(
                            SimpleCdclSolverEvent::Propagate { idx, assign: val, reason: clause_id }
                        )?;
                        trail.push_step(lit, AssignmentReason::UnitPropagation { clause_id });
                        continue 'outer;
                    }
                    ClauseState::Unsatisfied => return Ok(Some(clause_id)),
                    _ => {}
                }
            }
            break;
        }
        Ok(None)
    }
    // ~/~ end

    // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_resolve>>[init]
    //| id: scdcl_resolve
    fn resolve(
        &self,
        trail: &mut Trail,
        resolve_lit: Lit,
        reason_clause: &Clause,
        conflict_clause: &mut Clause,
        presence: &mut Vec<Option<usize>>,
        backtrack_level: &mut usize,
        current_level_lits: &mut HashSet<Lit>
    ) {
        // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdre_remove-lit>>[init]
        //| id: scdre_remove-lit
        let resolve_lit_var_id = resolve_lit.var_id;
        let resolve_lit_id = presence[resolve_lit_var_id].expect("resolve literal must exist in the learnt clause");
        current_level_lits.remove(&resolve_lit.inv());
        conflict_clause.lits.swap_remove(resolve_lit_id);
        presence[resolve_lit_var_id] = None;
        if resolve_lit_id < conflict_clause.lits.len() {
            let swaped_lit = &conflict_clause.lits[resolve_lit_id];
            presence[swaped_lit.var_id] = Some(resolve_lit_id);
        };
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdre_add-lit>>[init]
        //| id: scdre_add-lit
        for lit in &reason_clause.lits {
            let var_id = lit.var_id;
            if presence[var_id].is_some() || var_id == resolve_lit_var_id {
                continue;
            }

            let idx = conflict_clause.lits.len();
            conflict_clause.lits.push(lit.clone());
            presence[var_id] = Some(idx);

            let decision_level = trail.decision_levels[lit.var_id].expect("literal in reason clause must have a decision level");
            if decision_level < trail.current_decision_level {
                *backtrack_level = (*backtrack_level).max(decision_level);
            } else if decision_level == trail.current_decision_level {
                current_level_lits.insert(lit.clone());
            }
        }
        // ~/~ end
    }
    // ~/~ end

    // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_analyze-conflict>>[init]
    //| id: scdcl_analyze-conflict
    fn analyze_conflict(
        &mut self,
        trail: &mut Trail,
        conflict_clause_id: usize
    ) -> Result<(usize, Lit, usize), H::Error> {
        // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdac_setup>>[init]
        //| id: scdac_setup
        let mut learnt_clause = self.cnf.clauses[conflict_clause_id].clone();
        let mut current_level_lits = HashSet::new();
        let mut presence = vec![None; self.cnf.num_vars];
        let mut trail_pos = trail.trail.len() - 1;
        let mut backtrack_level = 0;
        for (lit_id, lit) in learnt_clause.lits.iter().enumerate() {
            let id = lit.var_id;
            presence[id] = Some(lit_id);
            if trail.decision_levels[id]
                .expect("literal must have been assigned") == trail.current_decision_level {
                current_level_lits.insert(lit.clone());
            }
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdac_loop>>[init]
        //| id: scdac_loop
        while current_level_lits.len() > 1 {
            // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdac_choose-literal>>[init]
            //| id: scdac_choose-literal
            let last_assigned_lit = loop {
                let lit = trail.trail[trail_pos].lit.clone();
                if let Some(_) = presence[lit.var_id] {
                    break lit;
                }
                trail_pos -= 1;
            };
            // ~/~ end
            // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdac_resolve>>[init]
            //| id: scdac_resolve
            let reason_clause_id = match trail.trail[trail_pos].reason {
                AssignmentReason::UnitPropagation { clause_id } => {clause_id},
                AssignmentReason::Decision => panic!("conflict clause should not select a decision literal at this stage")
            };
            self.resolve(
                trail,
                last_assigned_lit.clone(),
                &self.cnf.clauses[reason_clause_id],
                &mut learnt_clause,
                &mut presence,
                &mut backtrack_level,
                &mut current_level_lits
            );
            self.handler.handle_event(
                SimpleCdclSolverEvent::Resolve {
                    lit: last_assigned_lit,
                    reason_clause_id,
                    learnt_clause: learnt_clause.clone()
            })?;
            // ~/~ end
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdac_finalize>>[init]
        //| id: scdac_finalize
        self.handler.handle_event(SimpleCdclSolverEvent::LearntClause { clause: learnt_clause.clone() })?;
        self.cnf.clauses.push(learnt_clause);
        Ok((
            backtrack_level,
            current_level_lits
                .iter().next()
                .expect("current level set should contain at least one element").clone(),
            self.cnf.clauses.len() - 1
        ))
        // ~/~ end
    }
    // ~/~ end

    // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_cdcl>>[init]
    //| id: scdcl_cdcl
    fn cdcl(&mut self) -> Result<SatResult, H::Error> {
        // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_setup>>[init]
        //| id: scdcl_setup
        let mut trail = Trail {
            trail: vec![],
            assign: Assignment {
                values: vec![None; self.cnf.num_vars]
            },
            decision_levels: vec![None; self.cnf.num_vars],
            current_decision_level: 0
        };
        // ~/~ end
        loop {
            // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_bcp>>[init]
            //| id: scdcl_bcp
            let bcp_result = self.repeat_unit_propagate(&mut trail)?;
            // ~/~ end
            // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_conflict>>[init]
            //| id: scdcl_conflict
            if let Some(conflict_clause_id) = bcp_result {
                self.handler.handle_event(SimpleCdclSolverEvent::Conflict { reason: conflict_clause_id })?;
                if trail.current_decision_level == 0 {
                    self.handler.handle_event(SimpleCdclSolverEvent::RootConflict)?;
                    return Ok(SatResult::Unsat);
                }

                let (backtrack_level, assert_lit, learnt_clause_id) =
                    self.analyze_conflict(&mut trail, conflict_clause_id)?;
                self.handler.handle_event(SimpleCdclSolverEvent::BacktrackTo { level: backtrack_level })?;
                trail.backtrack(backtrack_level);

                trail.push_step(
                    assert_lit.clone(),
                    AssignmentReason::UnitPropagation { clause_id: learnt_clause_id }
                );
                self.handler.handle_event(
                    SimpleCdclSolverEvent::Propagate {
                        idx: assert_lit.var_id,
                        assign: !assert_lit.negated,
                        reason: learnt_clause_id
                    }
                )?;
            }
            // ~/~ end
            // ~/~ begin <<rust/viska-sat/src/simple_cdcl.typ#scdcl_decide>>[init]
            //| id: scdcl_decide
            else {
                if let Some(var_id) = self.pick_unassigned_var(&trail.assign) {
                    self.handler.handle_event(
                        SimpleCdclSolverEvent::Decide { idx: var_id, assign: true }
                    )?;
                    trail.push_step(Lit {var_id, negated: false}, AssignmentReason::Decision);
                } else {
                    return Ok(SatResult::Sat(trail.assign));
                }
            }
            // ~/~ end
        }
    }
    // ~/~ end
}

impl<H> Solver for SimpleCdclSolver<H>
where
    H: EventHandler<Event = SimpleCdclSolverEvent>
{
    type Event = SimpleCdclSolverEvent;
    type Handler = H;
    type Error = H::Error;

    fn solve(&mut self) -> Result<SatResult, Self::Error> {
        let result = self.cdcl()?;
        self.handler.handle_event(SimpleCdclSolverEvent::Finish { result: result.clone() })?;
        Ok(result)
    }
}
// ~/~ end
