package harness

import (
	"fmt"
	"os"
)

// IsolatedContext manages the lifecycle of an isolated evaluation environment.
// It provides a temporary working directory and ensures proper cleanup.
// Follow Go's t.TempDir() pattern for usage with defer.
type IsolatedContext struct {
	workingDir string
	cleaned    bool
}

// NewIsolatedContext creates a new isolated context with a fresh temporary directory.
// The temporary directory is created with the prefix "yokay-eval-".
// It is the caller's responsibility to call Cleanup() when done, typically via defer.
//
// Example usage:
//
//	ctx, err := NewIsolatedContext()
//	if err != nil {
//	    return err
//	}
//	defer ctx.Cleanup()
//
//	// Use ctx.WorkingDir() for eval execution
func NewIsolatedContext() (*IsolatedContext, error) {
	tmpDir, err := os.MkdirTemp("", "yokay-eval-")
	if err != nil {
		return nil, fmt.Errorf("creating temp directory: %w", err)
	}

	return &IsolatedContext{
		workingDir: tmpDir,
		cleaned:    false,
	}, nil
}

// WorkingDir returns the path to the temporary working directory.
// This directory is created during NewIsolatedContext and exists until Cleanup is called.
func (c *IsolatedContext) WorkingDir() string {
	return c.workingDir
}

// Cleanup removes the temporary working directory and all its contents.
// It is safe to call Cleanup multiple times; subsequent calls are no-ops.
// This method should typically be called via defer immediately after creating the context.
func (c *IsolatedContext) Cleanup() error {
	if c.cleaned {
		return nil
	}

	if err := os.RemoveAll(c.workingDir); err != nil {
		return fmt.Errorf("removing temp directory: %w", err)
	}

	c.cleaned = true
	return nil
}
