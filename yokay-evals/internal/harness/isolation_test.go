package harness

import (
	"os"
	"path/filepath"
	"testing"
)

func TestNewIsolatedContext(t *testing.T) {
	ctx, err := NewIsolatedContext()
	if err != nil {
		t.Fatalf("NewIsolatedContext() error = %v, want nil", err)
	}
	defer ctx.Cleanup()

	if ctx == nil {
		t.Fatal("NewIsolatedContext() returned nil context")
	}

	workingDir := ctx.WorkingDir()
	if workingDir == "" {
		t.Error("WorkingDir() returned empty string")
	}

	// Verify temp directory has the expected prefix
	baseName := filepath.Base(workingDir)
	if len(baseName) < 11 || baseName[:11] != "yokay-eval-" {
		t.Errorf("WorkingDir() base name = %q, want prefix 'yokay-eval-'", baseName)
	}
}

func TestWorkingDirExistsAndWritable(t *testing.T) {
	ctx, err := NewIsolatedContext()
	if err != nil {
		t.Fatalf("NewIsolatedContext() error = %v, want nil", err)
	}
	defer ctx.Cleanup()

	workingDir := ctx.WorkingDir()

	// Check that directory exists
	info, err := os.Stat(workingDir)
	if err != nil {
		t.Fatalf("WorkingDir() directory does not exist: %v", err)
	}

	if !info.IsDir() {
		t.Errorf("WorkingDir() = %q is not a directory", workingDir)
	}

	// Check that directory is writable
	testFile := filepath.Join(workingDir, "test.txt")
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Errorf("WorkingDir() directory is not writable: %v", err)
	}
}

func TestCleanupRemovesTempDirectory(t *testing.T) {
	ctx, err := NewIsolatedContext()
	if err != nil {
		t.Fatalf("NewIsolatedContext() error = %v, want nil", err)
	}

	workingDir := ctx.WorkingDir()

	// Verify directory exists before cleanup
	if _, err := os.Stat(workingDir); err != nil {
		t.Fatalf("WorkingDir() directory does not exist before cleanup: %v", err)
	}

	// Call cleanup
	if err := ctx.Cleanup(); err != nil {
		t.Errorf("Cleanup() error = %v, want nil", err)
	}

	// Verify directory no longer exists
	if _, err := os.Stat(workingDir); !os.IsNotExist(err) {
		t.Errorf("WorkingDir() directory still exists after cleanup")
	}
}

func TestCleanupIdempotent(t *testing.T) {
	ctx, err := NewIsolatedContext()
	if err != nil {
		t.Fatalf("NewIsolatedContext() error = %v, want nil", err)
	}

	// Call cleanup multiple times
	if err := ctx.Cleanup(); err != nil {
		t.Errorf("First Cleanup() error = %v, want nil", err)
	}

	if err := ctx.Cleanup(); err != nil {
		t.Errorf("Second Cleanup() error = %v, want nil", err)
	}

	if err := ctx.Cleanup(); err != nil {
		t.Errorf("Third Cleanup() error = %v, want nil", err)
	}
}

func TestMultipleIsolatedContexts(t *testing.T) {
	// Create multiple contexts to verify they get unique directories
	ctx1, err := NewIsolatedContext()
	if err != nil {
		t.Fatalf("NewIsolatedContext() #1 error = %v, want nil", err)
	}
	defer ctx1.Cleanup()

	ctx2, err := NewIsolatedContext()
	if err != nil {
		t.Fatalf("NewIsolatedContext() #2 error = %v, want nil", err)
	}
	defer ctx2.Cleanup()

	dir1 := ctx1.WorkingDir()
	dir2 := ctx2.WorkingDir()

	if dir1 == dir2 {
		t.Errorf("Multiple contexts have the same working directory: %q", dir1)
	}

	// Both should exist
	if _, err := os.Stat(dir1); err != nil {
		t.Errorf("Context #1 working directory does not exist: %v", err)
	}
	if _, err := os.Stat(dir2); err != nil {
		t.Errorf("Context #2 working directory does not exist: %v", err)
	}
}
