# 🎵 Bass in a Voice — Music Knowledge Base

**Created:** 2026-03-22  
**Agent:** Lola  
**Purpose:** Agent-first system for managing Bass in a Voice musical project

---

## 📂 Structure

```
memory/music/
├── README.md                       # This file
├── agent-instructions.md           # How Lola helps with Bass in a Voice
├── bass-in-a-voice-profile.md      # Band profile and info
├── session-template.md             # Template for rehearsal/gig notes
├── repertoire.md                   # Song list, arrangements, status
├── youtube-plan.md                 # Content planning and tracking
├── gear-inventory.md               # Equipment tracking
├── sessions/                       # Notes from rehearsals/gigs
│   └── YYYY-MM-DD-type.md
├── setlists/                       # Setlists for specific events
│   └── YYYY-MM-DD-venue.md
└── arrangements/                   # Detailed arrangements per song
    └── song-name.md
```

---

## 🎯 Agent-First Concept

This knowledge base is designed for **Lola to consume data and respond to questions**, not for Manu to navigate manually.

### How It Works

1. **Manu asks:** "¿Qué trabajamos en el último ensayo?"
2. **Lola reads:** Latest file in `sessions/`
3. **Lola responds:** With context from that session + repertoire + next steps

### Examples

- "¿Cuándo es el próximo ensayo?" → Google Calendar + `schedule.md`
- "¿Qué canciones tenemos listas?" → `repertoire.md` (sección Activo)
- "Ideas para video de YouTube" → `youtube-plan.md` + recent sessions
- "¿Qué necesitamos practicar?" → Session notes + repertoire status

---

## 📊 Data Flow

```
Input Sources → Knowledge Base → Lola → Manu
     ↓               ↓             ↓       ↓
  Calendar      agent-instructions  Query  Answer
  Sessions      repertoire.md      "¿?"   Context
  YouTube       gear-inventory.md
  Notes         session files
```

---

## 🔄 Maintenance

- **After rehearsal/gig:** Create session note using template
- **New song added:** Update `repertoire.md`
- **Video published:** Update `youtube-plan.md`
- **Gear change:** Update `gear-inventory.md`
- **Monthly:** Review and consolidate

---

## ✨ Phase 4 Integration

This is part of the **Master Plan Phase 4** — applying the agent-first pattern to music alongside surf coaching, health tracking, and finance.

**Goal:** Lola as a proactive band manager assistant that helps Manu create better music and manage the project effortlessly.

---

*"Manu pregunta, Lola responde con contexto." — Agent-first philosophy*
