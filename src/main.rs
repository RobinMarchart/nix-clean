use std::{
    env::current_dir,
    ffi::OsStr,
    fs::{exists, read_dir, remove_dir_all, remove_file},
    os::unix::ffi::OsStrExt,
    path::Path,
    process::Command,
};

use color_eyre::{eyre::Context, Result};
fn main() -> Result<()> {
    color_eyre::install()?;
    iter_dir(&current_dir()?)
}

fn iter_dir(path: &Path) -> Result<()> {
    for entry in read_dir(path).context("open dir for iteration")? {
        let entry = entry.context("reading dir entry")?;
        let file_type = entry.file_type().context("getting file type")?;
        let name = entry.file_name();
        if file_type.is_file() {
            if name == OsStr::new("flake.lock") {
                println!("found flake at {}", entry.path().display());
                Command::new("nix")
                    .arg("flake")
                    .arg("update")
                    .current_dir(path)
                    .spawn()
                    .context("starting flake update")?
                    .wait()
                    .context("running flake update")?;
            } else if name == OsStr::new("Cargo.lock") {
                println!("found rust at {}", path.display());
                Command::new("cargo")
                    .arg("update")
                    .current_dir(path)
                    .spawn()
                    .context("starting cargo update")?
                    .wait()
                    .context("running cargo update")?;
                Command::new("cargo")
                    .arg("clean")
                    .current_dir(path)
                    .spawn()
                    .context("starting cargo clean")?
                    .wait()
                    .context("running cargo clean")?;
            }
        } else if file_type.is_dir() {
            if name == OsStr::new(".direnv") {
                let path = entry.path();
                println!("found direnv dir at {}", path.display());
                remove_dir_all(&path).context("removing direnv dir")?;
            } else if name == OsStr::new("node_modules") {
                println!("node_modules at {}", entry.path().display());
                remove_dir_all(&entry.path()).context("removing node_modules dir")?;
            } else if !name.is_empty()
                && name.as_bytes()[0] != b'.'
                && exists(&entry.path()).context("checking if directory still exists")?
            {
                iter_dir(&entry.path())?;
            }
        } else if file_type.is_symlink() && name == OsStr::new("result") {
            let path = entry.path();
            println!("found result symlink at {}", path.display());
            remove_file(&path)?;
        }
    }
    Ok(())
}
