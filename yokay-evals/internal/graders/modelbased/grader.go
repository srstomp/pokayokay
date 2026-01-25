package modelbased

// Grader is the interface that all model-based graders must implement.
// Model-based graders use LLM evaluation to assess content quality.
type Grader interface {
	// Grade evaluates the input content and returns a result with score and feedback
	Grade(input GradeInput) (Result, error)
}

// GradeInput represents the input data to be graded
type GradeInput struct {
	// Content is the text content to be evaluated
	Content string
	// Context provides additional metadata or parameters for grading
	Context map[string]any
}

// Result represents the grading outcome
type Result struct {
	// Passed indicates whether the content meets the minimum quality threshold
	Passed bool
	// Score is the numeric grade (typically 0-100)
	Score float64
	// Message provides human-readable feedback about the grading
	Message string
	// Details contains structured feedback for each evaluation criterion
	Details map[string]any
}
