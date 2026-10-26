// rtk-bar — JSON status for DMS bar plugin (projects with/without RTK usage).
package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

type projectStat struct {
	Path      string  `json:"path"`
	Name      string  `json:"name"`
	Commands  int     `json:"commands"`
	Saved     int64   `json:"saved_tokens"`
	LastSeen  string  `json:"last_seen,omitempty"`
	HasRTK    bool    `json:"has_rtk"`
	SavingsPct float64 `json:"savings_pct,omitempty"`
}

type report struct {
	Summary struct {
		ProjectsTotal   int   `json:"projects_total"`
		WithRTK         int   `json:"with_rtk"`
		WithoutRTK      int   `json:"without_rtk"`
		SavedTokensAll  int64 `json:"saved_tokens_all"`
		CommandsAll     int   `json:"commands_all"`
	} `json:"summary"`
	Without []projectStat `json:"without_rtk"`
	With    []projectStat `json:"with_rtk"`
	Updated string        `json:"updated"`
}

func main() {
	projectsRoot := flag.String("root", filepath.Join(os.Getenv("HOME"), "Documents", "Projetos"), "projects directory to scan")
	dbPath := flag.String("db", filepath.Join(os.Getenv("HOME"), ".local", "share", "rtk", "history.db"), "rtk history db")
	flag.Parse()

	db, err := sql.Open("sqlite", *dbPath)
	if err != nil {
		fatal(err)
	}
	defer db.Close()

	type agg struct {
		cmds   int
		saved  int64
		inTok  int64
		last   string
	}
	byPath := map[string]*agg{}

	rows, err := db.Query(`
		SELECT COALESCE(project_path,''), COUNT(*), COALESCE(SUM(saved_tokens),0),
		       COALESCE(SUM(input_tokens),0), COALESCE(MAX(timestamp),'')
		FROM commands
		GROUP BY COALESCE(project_path,'')
	`)
	if err != nil {
		fatal(err)
	}
	defer rows.Close()
	var totalSaved int64
	var totalCmds int
	for rows.Next() {
		var path string
		var a agg
		var inTok int64
		if err := rows.Scan(&path, &a.cmds, &a.saved, &inTok, &a.last); err != nil {
			fatal(err)
		}
		a.inTok = inTok
		totalSaved += a.saved
		totalCmds += a.cmds
		if path == "" {
			continue
		}
		byPath[path] = &a
	}

	entries, _ := os.ReadDir(*projectsRoot)
	var with, without []projectStat
	seen := map[string]bool{}

	for _, e := range entries {
		if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		full := filepath.Join(*projectsRoot, e.Name())
		seen[full] = true
		ps := projectStat{Path: full, Name: e.Name()}
		// match exact or any child path under this project
		var matched *agg
		for p, a := range byPath {
			if p == full || strings.HasPrefix(p, full+string(os.PathSeparator)) {
				if matched == nil {
					matched = &agg{}
				}
				matched.cmds += a.cmds
				matched.saved += a.saved
				matched.inTok += a.inTok
				if a.last > matched.last {
					matched.last = a.last
				}
			}
		}
		configured := hasRtkInstructions(full)
		if matched != nil && matched.cmds > 0 {
			ps.HasRTK = true
			ps.Commands = matched.cmds
			ps.Saved = matched.saved
			ps.LastSeen = matched.last
			if matched.inTok > 0 {
				ps.SavingsPct = float64(matched.saved) / float64(matched.inTok) * 100
			}
			with = append(with, ps)
		} else if configured {
			ps.HasRTK = true
			with = append(with, ps)
		} else {
			ps.HasRTK = false
			without = append(without, ps)
		}
	}

	sort.Slice(without, func(i, j int) bool { return without[i].Name < without[j].Name })
	sort.Slice(with, func(i, j int) bool { return with[i].Saved > with[j].Saved })

	var r report
	r.Summary.ProjectsTotal = len(with) + len(without)
	r.Summary.WithRTK = len(with)
	r.Summary.WithoutRTK = len(without)
	r.Summary.SavedTokensAll = totalSaved
	r.Summary.CommandsAll = totalCmds
	r.Without = without
	r.With = with
	r.Updated = time.Now().Format(time.RFC3339)

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	_ = enc.Encode(r)
}

func fatal(err error) {
	fmt.Fprintf(os.Stderr, "rtk-bar: %v\n", err)
	os.Exit(1)
}

// hasRtkInstructions reports whether the project already has RTK agent instructions
// (same artifact `rtk init --claude-md` writes).
func hasRtkInstructions(dir string) bool {
	for _, name := range []string{"CLAUDE.md", "RTK.md", "AGENTS.md"} {
		data, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			continue
		}
		s := string(data)
		if strings.Contains(s, "rtk-instructions") ||
			strings.Contains(s, "Rust Token Killer") ||
			strings.Contains(s, "Always prefix commands with `rtk`") {
			return true
		}
	}
	return false
}
