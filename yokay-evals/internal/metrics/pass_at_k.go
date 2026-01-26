package metrics

// PassAtK evaluates the pass@k metric for a set of evaluation results.
//
// pass@k is a capability measure that answers the question:
// "Can the system succeed at least once in k tries?"
//
// It returns true if at least one result in the slice is true,
// indicating the system is capable of producing a successful outcome.
// Returns false if all results are false or if the slice is empty.
//
// Example use cases:
// - Measuring if a code generation system can produce correct code
// - Evaluating if a search system can find the right answer
// - Determining if a system has the capability to solve a problem
//
// Semantics:
//   - PassAtK([]bool{true, false, false}) → true (capable, succeeded once)
//   - PassAtK([]bool{false, false, false}) → false (not capable)
//   - PassAtK([]bool{}) → false (no evidence of capability)
func PassAtK(results []bool) bool {
	for _, result := range results {
		if result {
			return true
		}
	}
	return false
}

// PassCaretK evaluates the pass^k metric for a set of evaluation results.
//
// pass^k is a consistency measure that answers the question:
// "Does the system succeed every time in k tries?"
//
// It returns true only if all results in the slice are true,
// indicating the system consistently produces successful outcomes.
// Returns false if any result is false or if the slice is empty.
//
// Example use cases:
// - Measuring reliability of a production system
// - Evaluating consistency of model outputs
// - Determining if a system is stable enough for deployment
//
// Semantics:
//   - PassCaretK([]bool{true, true, true}) → true (consistent)
//   - PassCaretK([]bool{true, false, true}) → false (inconsistent)
//   - PassCaretK([]bool{}) → false (no evidence of consistency)
func PassCaretK(results []bool) bool {
	if len(results) == 0 {
		return false
	}

	for _, result := range results {
		if !result {
			return false
		}
	}
	return true
}
