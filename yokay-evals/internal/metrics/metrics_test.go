package metrics

import (
	"testing"
)

func TestPassAtK(t *testing.T) {
	tests := []struct {
		name     string
		results  []bool
		expected bool
	}{
		{
			name:     "k=1, single pass",
			results:  []bool{true},
			expected: true,
		},
		{
			name:     "k=1, single fail",
			results:  []bool{false},
			expected: false,
		},
		{
			name:     "all pass",
			results:  []bool{true, true, true},
			expected: true,
		},
		{
			name:     "all fail",
			results:  []bool{false, false, false},
			expected: false,
		},
		{
			name:     "mixed with success - majority pass",
			results:  []bool{true, true, false},
			expected: true,
		},
		{
			name:     "mixed with success - single success at end",
			results:  []bool{false, false, true},
			expected: true,
		},
		{
			name:     "empty slice",
			results:  []bool{},
			expected: false,
		},
		{
			name:     "single success in middle",
			results:  []bool{false, true, false, false},
			expected: true,
		},
		{
			name:     "large k with one success",
			results:  []bool{false, false, false, false, false, false, false, false, false, true},
			expected: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := PassAtK(tt.results)
			if result != tt.expected {
				t.Errorf("PassAtK(%v) = %v, expected %v", tt.results, result, tt.expected)
			}
		})
	}
}

func TestPassCaretK(t *testing.T) {
	tests := []struct {
		name     string
		results  []bool
		expected bool
	}{
		{
			name:     "k=1, single pass",
			results:  []bool{true},
			expected: true,
		},
		{
			name:     "k=1, single fail",
			results:  []bool{false},
			expected: false,
		},
		{
			name:     "all pass",
			results:  []bool{true, true, true},
			expected: true,
		},
		{
			name:     "all fail",
			results:  []bool{false, false, false},
			expected: false,
		},
		{
			name:     "mixed - majority pass but not all",
			results:  []bool{true, true, false},
			expected: false,
		},
		{
			name:     "mixed - single success not enough",
			results:  []bool{false, false, true},
			expected: false,
		},
		{
			name:     "empty slice",
			results:  []bool{},
			expected: false,
		},
		{
			name:     "single failure ruins consistency",
			results:  []bool{true, true, true, false, true},
			expected: false,
		},
		{
			name:     "large k all pass",
			results:  []bool{true, true, true, true, true, true, true, true, true, true},
			expected: true,
		},
		{
			name:     "large k with one fail",
			results:  []bool{true, true, true, true, true, true, true, true, true, false},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := PassCaretK(tt.results)
			if result != tt.expected {
				t.Errorf("PassCaretK(%v) = %v, expected %v", tt.results, result, tt.expected)
			}
		})
	}
}

// TestPassAtKSemantics verifies the capability measure semantics
func TestPassAtKSemantics(t *testing.T) {
	t.Run("pass@k measures capability - succeeds at least once", func(t *testing.T) {
		// Even with mostly failures, one success means capable
		results := []bool{false, false, false, false, false, false, false, false, false, true}
		if !PassAtK(results) {
			t.Error("pass@k should return true if capable of succeeding at least once")
		}
	})

	t.Run("pass@k returns false only when never succeeds", func(t *testing.T) {
		results := []bool{false, false, false, false, false}
		if PassAtK(results) {
			t.Error("pass@k should return false when never succeeds")
		}
	})
}

// TestPassCaretKSemantics verifies the consistency measure semantics
func TestPassCaretKSemantics(t *testing.T) {
	t.Run("pass^k measures consistency - must succeed every time", func(t *testing.T) {
		// All successes required for consistency
		results := []bool{true, true, true, true, true}
		if !PassCaretK(results) {
			t.Error("pass^k should return true when succeeds every time")
		}
	})

	t.Run("pass^k returns false with any failure", func(t *testing.T) {
		// Single failure breaks consistency
		results := []bool{true, true, true, true, false}
		if PassCaretK(results) {
			t.Error("pass^k should return false with any failure")
		}
	})
}
